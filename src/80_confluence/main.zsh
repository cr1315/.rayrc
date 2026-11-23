#!/usr/bin/env zsh
######################################################################
##
## Confluence Cloud のページを zip で取り込む・書き出す関数（main.ps1 の zsh 版）
##
##   confluence-import 330137615_promote.zip     # zip の中身でページを更新する
##   confluence-import -p 330137615 a.zip b.zip  # 親の子として取り込む（同じタイトルの子があれば更新、なければ作る）
##   confluence-export 330137615                 # ページを zip に書き出す（URL でもよい）
##   confluence-export -r 330137615              # 子孫のページも書き出す（下の「入れ子」の形）
##
## 環境変数（なければ、そのつど入力を求める）
##   RAYRC_JIRA_BASE_URL  ページ ID だけを渡したときのサイトの URL（例：https://xxx.atlassian.net）
##   RAYRC_JIRA_EMAIL     ホスト名ごとの Atlassian のメールアドレス
##   RAYRC_JIRA_TOKEN     ホスト名ごとの API トークン（https://id.atlassian.com/manage-profile/security/api-tokens）
##
##   RAYRC_JIRA_EMAIL と RAYRC_JIRA_TOKEN は「ホスト名=値」をカンマか空白（改行でもよい）で区切って並べる。
##   値は最初の = より後ろ全部（トークンが = を含んでもよい）。ホスト名の大文字・小文字は区別しない。
##     RAYRC_JIRA_EMAIL='xxx.atlassian.net=me@example.com,yyy.atlassian.net=me@example.org'
##     RAYRC_JIRA_TOKEN='xxx.atlassian.net=ATATT...,yyy.atlassian.net=ATATT...'
##   秘密情報なので、このリポジトリの外で export すること。
##
## zip の決まり
##   - 中に page.xhtml（ストレージ形式の本文）が 1 つあること。図などはその隣に置く
##   - 名前が「<ページ ID>_<名前>.zip」なら、ページ ID はそこから読む（-u を省略できる）
##   - page.json があれば、親の子として取り込むときのタイトルをそこから読む
##
## 入れ子（-r）
##   子のページは、親の zip と同じ名前のフォルダに置く。孫以下も同じ。
##   子の並び順は、親の page.json の children に書く（書いていない子は名前の順）
##     123_親.zip
##     123_親/456_子.zip
##     123_親/456_子/789_孫.zip
##
## 使うコマンド：curl、jq、zip、unzip、sha256sum（なければ shasum）
##
######################################################################

# ---- 共通 ----

__rayrc_cf_err() {
    print -ru2 -- "confluence: $*"
}

## __rayrc_cf_need <コマンド...>
__rayrc_cf_need() {
    emulate -L zsh
    local c
    for c in "$@"; do
        if ! (( ${+commands[$c]} )); then
            __rayrc_cf_err "${c} が見つかりません"
            return 8
        fi
    done
}

## __rayrc_cf_site [<URL>] → REPLY=https://<ホスト名>
## URL がなければ RAYRC_JIRA_BASE_URL、それもなければ入力を求める
__rayrc_cf_site() {
    emulate -L zsh -o extended_glob
    local site="${1:-${RAYRC_JIRA_BASE_URL}}"
    if [[ -z "${site}" ]]; then
        read -r "site?Atlassian のサイトの URL（例：https://xxx.atlassian.net）: " || return 8
    fi
    if [[ "${site}" != (#b)[[:space:]]#(https://[^/[:space:]]##)* ]]; then
        __rayrc_cf_err "サイトの URL の形が違います：${site}"
        return 8
    fi
    REPLY="${(L)match[1]}"
}

## __rayrc_cf_resolve_page <URL かページ ID> → reply=(<サイト> <ページ ID>)
__rayrc_cf_resolve_page() {
    emulate -L zsh -o extended_glob
    local ref="${1//\"/}"
    ref="${${ref##[[:space:]]#}%%[[:space:]]#}"

    if [[ "${ref}" == [0-9]## ]]; then
        __rayrc_cf_site || return 8
        reply=("${REPLY}" "${ref}")
        return 0
    fi

    if [[ "${ref}" == (#b)(https://[^/]##)/wiki/* ]]; then
        local site="${(L)match[1]}"
        local seg
        local -a segs
        ## /pages/ の後ろで、最初の数字だけのところがページ ID（edit-v2 などは読み飛ばす）
        segs=("${(@s:/:)${${ref#https://*/wiki/}%%[?#]*}}")
        if (( ${segs[(Ie)pages]} )); then
            for seg in "${(@)segs[${segs[(i)pages]}+1,-1]}"; do
                if [[ "${seg}" == [0-9]## ]]; then
                    reply=("${site}" "${seg}")
                    return 0
                fi
                [[ "${seg}" == [a-z0-9-]## ]] || break
            done
        fi
        if [[ "${ref}" == (#b)*[?\&]pageId=([0-9]##)(|[^0-9]*) ]]; then
            reply=("${site}" "${match[1]}")
            return 0
        fi
    fi

    __rayrc_cf_err "ページの URL か ID を指定してください（/pages/<数字>/ か pageId=<数字> を含む URL。短縮 URL /wiki/x/... は不可）：${ref}"
    return 8
}

## __rayrc_cf_lookup <変数名> <ホスト名> → REPLY=<値>
## 変数の中身は「ホスト名=値」をカンマか空白で区切ったもの。見つからなければ 1 を返す
__rayrc_cf_lookup() {
    emulate -L zsh
    local name="$1"
    local host="${(L)2}"
    local entry
    REPLY=''
    for entry in ${(s:,:)${${(P)name}//[[:space:]]/,}}; do
        if [[ "${entry}" != ?*=?* ]]; then
            ## 値は秘密情報なので、表示しない
            __rayrc_cf_err "${name} に「ホスト名=値」の形でないものがあるので無視します"
            continue
        fi
        if [[ "${(L)entry%%=*}" == "${host}" ]]; then
            REPLY="${entry#*=}"
            return 0
        fi
    done
    return 1
}

## __rayrc_cf_auth <ホスト名> [<メールアドレス>] → REPLY=<メールアドレス>:<トークン>
__rayrc_cf_auth() {
    emulate -L zsh
    local host="$1"
    local email="$2"
    local token=''

    if [[ -z "${email}" ]] && __rayrc_cf_lookup RAYRC_JIRA_EMAIL "${host}"; then
        email="${REPLY}"
    fi
    if [[ -z "${email}" ]]; then
        read -r "email?Atlassian のメールアドレス（${host}）: " || return 8
    fi
    if __rayrc_cf_lookup RAYRC_JIRA_TOKEN "${host}"; then
        token="${REPLY}"
    else
        read -rs "token?API トークン（${host}）: " || return 8
        print -u2
    fi
    if [[ -z "${email}" || -z "${token}" ]]; then
        __rayrc_cf_err "メールアドレスと API トークンが要ります（${host}）"
        return 8
    fi
    REPLY="${email}:${token}"
}

## __rayrc_cf_curl <認証> <出力ファイル> <curl の引数...>
## 出力ファイルが空なら、応答を REPLY に入れる。認証は ps に出ないよう標準入力から渡す
__rayrc_cf_curl() {
    emulate -L zsh
    local auth="$1"
    local out="$2"
    shift 2

    local tmp=''
    if [[ -z "${out}" ]]; then
        tmp="$(mktemp)" || return 8
        out="${tmp}"
    fi

    local code rc
    code="$(curl -sS -L -K - -o "${out}" -w '%{http_code}' "$@" <<<"user = \"${auth}\"")"
    rc=$?
    if (( rc != 0 || code >= 400 )); then
        __rayrc_cf_err "API の呼び出しに失敗しました（HTTP ${code}。認証・権限・URL を確認）：${@[-1]}"
        [[ -f "${out}" ]] && { cat -- "${out}" >&2; print -u2; }
        [[ -n "${tmp}" ]] && rm -f -- "${tmp}"
        return 8
    fi
    if [[ -n "${tmp}" ]]; then
        REPLY="$(<"${tmp}")"
        rm -f -- "${tmp}"
    fi
}

## __rayrc_cf_list <認証> <URL（? を含み、start= を除く）> → REPLY=<全ページ分の results をつないだ JSON 配列>
__rayrc_cf_list() {
    emulate -L zsh
    local all='[]'
    local start=0
    local page
    while true; do
        __rayrc_cf_curl "$1" '' "$2&start=${start}" || return 8
        page="${REPLY}"
        all="$(jq -c --argjson a "${all}" '$a + .results' <<<"${page}")" || return 8
        (( start += $(jq -r '.size' <<<"${page}") ))
        [[ -n "$(jq -r '._links.next // empty' <<<"${page}")" ]] || break
    done
    REPLY="${all}"
}

## __rayrc_cf_sha256 <ファイル> → REPLY=<16 進の小文字>
__rayrc_cf_sha256() {
    emulate -L zsh
    if (( ${+commands[sha256sum]} )); then
        REPLY="${$(sha256sum -- "$1")%% *}"
    else
        REPLY="${$(shasum -a 256 -- "$1")%% *}"
    fi
    [[ -n "${REPLY}" ]]
}

## __rayrc_cf_html_decode <文字列> → REPLY（ri:filename の中の &amp; や &#12354; を戻す）
__rayrc_cf_html_decode() {
    emulate -L zsh -o extended_glob
    local s="$1"
    local out=''
    local ent n
    while [[ "${s}" == (#b)([^\&]#)\&(\#[0-9]##|\#[xX][0-9a-fA-F]##|[a-zA-Z]##)\;(*) ]]; do
        out+="${match[1]}"
        ent="${match[2]}"
        s="${match[3]}"
        case "${ent}" in
            amp) out+='&' ;;
            lt) out+='<' ;;
            gt) out+='>' ;;
            quot) out+='"' ;;
            apos) out+="'" ;;
            \#[xX]*) n="16#${ent:2}"; out+="${(#)n}" ;;
            \#*) n="10#${ent:1}"; out+="${(#)n}" ;;
            *) out+="&${ent};" ;;
        esac
    done
    REPLY="${out}${s}"
}

# ---- 取り込み ----

## __rayrc_cf_import_page <認証> <サイト> <zip> <ページ ID> <親 ID> <タイトル> <版のメッセージ> <prune> <recursive>
## ページ ID があれば、そのページを更新する。
## なければ、親の子から同じタイトルのページを探して更新し、なければ親の子として作る。
## タイトルが空なら、更新のときは今のまま、親の子にするときは page.json（なければ zip の名前）から読む。
## recursive が true なら、zip と同じ名前のフォルダの中の zip を、このページの子として取り込む（孫以下も同じ）
## → REPLY=<ページ ID>
__rayrc_cf_import_page() {
    emulate -L zsh -o extended_glob
    local auth="$1"
    local site="$2"
    local zip="$3"
    local id="$4"
    local parent="$5"
    local title="$6"
    local message="$7"
    local prune="$8"
    local recursive="$9"
    local api="${site}/wiki/rest/api"
    local -a order

    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/confluence-import_XXXXXXXX")" || return 8
    {
        print -r -- "zip：${zip}"
        unzip -q "${zip}" -d "${work}" || return 8
        local -a found
        found=("${work}"/**/page.xhtml(N.))
        if (( ${#found} != 1 )); then
            __rayrc_cf_err "zip の中に page.xhtml がちょうど 1 つ必要です（見つかった数：${#found}）：${zip}"
            return 8
        fi
        local dir="${found[1]:h}"
        local meta="${dir}/page.json"
        [[ -f "${meta}" ]] || meta=''

        # 図（ページに書き込む前に、本文が参照している図が zip にそろっているかを確かめる）
        local w name file comment
        local -a wanted decoded missing
        for w in ${(f)"$(grep -oE 'ri:attachment ri:filename="[^"]+"' -- "${found[1]}")"}; do
            w="${${w#ri:attachment ri:filename=\"}%\"}"
            __rayrc_cf_html_decode "${w}"
            decoded+=("${REPLY}")
        done
        wanted=("${(@u)decoded}")
        for name in "${wanted[@]}"; do
            [[ -e "${dir}/${name}" ]] || missing+=("${name}")
        done
        if (( ${#missing} )); then
            __rayrc_cf_err "本文が参照している図が zip にありません：${(j:, :)missing}"
            return 8
        fi

        # ページ（親の子にするときは、同じタイトルの子を探す）
        if [[ -z "${id}" ]]; then
            if [[ -z "${title}" && -n "${meta}" ]]; then
                title="$(jq -r '.title // empty' "${meta}")" || return 8
            fi
            [[ -n "${title}" ]] || title="${${zip:t:r}#[0-9]##_}"
            __rayrc_cf_list "${auth}" "${api}/content/${parent}/child/page?limit=100" || return 8
            id="$(jq -r --arg t "${title}" 'first(.[] | select(.title == $t) | .id) // empty' <<<"${REPLY}")" || return 8
        fi

        local json="${work}/.payload.json"
        local created=false
        local version
        if [[ -n "${id}" ]]; then
            __rayrc_cf_curl "${auth}" '' "${api}/content/${id}?expand=version" || return 8
            local cur_title
            cur_title="$(jq -r '.title' <<<"${REPLY}")" || return 8
            version="$(jq -r '.version.number' <<<"${REPLY}")" || return 8
            [[ -n "${title}" ]] || title="${cur_title}"
            print -r -- "ページ：${cur_title}（版 ${version}、ID ${id}）"
        else
            ## 本文ごと作る。図はこのあと上げる
            __rayrc_cf_curl "${auth}" '' "${api}/content/${parent}?expand=space" || return 8
            local space
            space="$(jq -r '.space.key' <<<"${REPLY}")" || return 8
            jq -n --arg title "${title}" --arg space "${space}" --arg parent "${parent}" \
                --rawfile body "${found[1]}" \
                '{type: "page", title: $title, space: {key: $space}, ancestors: [{id: $parent}],
                  body: {storage: {value: ($body | if (explode[0] == 65279) then .[1:] else . end),
                                   representation: "storage"}}}' \
                >"${json}" || return 8
            __rayrc_cf_curl "${auth}" '' -X POST -H "Content-Type: application/json; charset=utf-8" \
                --data-binary "@${json}" "${api}/content" || return 8
            id="$(jq -r '.id' <<<"${REPLY}")" || return 8
            created=true
            print -r -- "ページ：${title}（新しく作成、ID ${id}、親 ID ${parent}）"
        fi

        __rayrc_cf_list "${auth}" "${api}/content/${id}/child/attachment?limit=100&expand=metadata" || return 8
        local -A r_id r_comment
        local t i c
        while IFS=$'\t' read -r t i c; do
            r_id[$t]="${i}"
            r_comment[$t]="${c}"
        done < <(jq -r '.[] | [.title, .id, (.metadata.comment // "")] | @tsv' <<<"${REPLY}")

        for name in "${wanted[@]}"; do
            file="${dir}/${name}"
            __rayrc_cf_sha256 "${file}" || return 8
            comment="sha256:${REPLY}"
            if (( ${+r_id[$name]} )) && [[ "${r_comment[$name]}" == "${comment}" ]]; then
                print -r -- "図：${name}（変更なし）"
                continue
            fi
            print -r -- "図：${name}（アップロード）"
            ## -F のファイル名は "" で囲む（; や , を含んでもよいように）。中の \ と " はエスケープする
            __rayrc_cf_curl "${auth}" '' -X PUT -H "X-Atlassian-Token: no-check" \
                -F "file=@\"${${file//\\/\\\\}//\"/\\\"}\"" \
                --form-string "comment=${comment}" --form-string "minorEdit=true" \
                "${api}/content/${id}/child/attachment" || return 8
        done
        if [[ "${prune}" == true ]]; then
            for t in "${(@k)r_id}"; do
                if [[ "${r_comment[$t]}" == sha256:* ]] && (( ! ${wanted[(Ie)$t]} )); then
                    print -r -- "図：${t}（本文が参照しなくなったので削除）"
                    __rayrc_cf_curl "${auth}" '' -X DELETE "${api}/content/${r_id[$t]}" || return 8
                fi
            done
        fi

        # 本文（作ったページは、作ったときに入れてある）
        if ${created}; then
            print -r -- "完了（新しく作成）：${site}/wiki/pages/viewpage.action?pageId=${id}"
        else
            jq -n --arg id "${id}" --arg title "${title}" --arg msg "${message}" \
                --argjson ver "$(( version + 1 ))" --rawfile body "${found[1]}" \
                '{id: $id, type: "page", title: $title,
                  version: {number: $ver, message: $msg},
                  body: {storage: {value: ($body | ltrimstr("\ufeff")), representation: "storage"}}}' \
                >"${json}" || return 8
            __rayrc_cf_curl "${auth}" '' -X PUT -H "Content-Type: application/json; charset=utf-8" \
                --data-binary "@${json}" "${api}/content/${id}" || return 8
            print -r -- "完了（版 $(( version + 1 ))）：${site}/wiki/pages/viewpage.action?pageId=${id}"
        fi

        if [[ "${recursive}" == true && -n "${meta}" ]]; then
            order=(${(f)"$(jq -r '.children[]?.id' "${meta}")"})
        fi
    } always {
        rm -rf -- "${work}"
    }

    # 子（zip と同じ名前のフォルダの中の zip）。page.json の children の順、書いていないものは名前の順
    if [[ "${recursive}" == true && -d "${zip:r}" ]]; then
        local -a zips sorted
        local k z
        zips=("${zip:r}"/*.zip(N.))
        for k in "${order[@]}"; do
            for z in "${zips[@]}"; do
                [[ "${z:t}" == "${k}"_* ]] && sorted+=("${z}")
            done
        done
        for z in "${zips[@]}"; do
            (( ${sorted[(Ie)$z]} )) || sorted+=("${z}")
        done
        for z in "${sorted[@]}"; do
            __rayrc_cf_import_page "${auth}" "${site}" "${z}" '' "${id}" '' "${message}" "${prune}" true || return 8
        done
    fi
    REPLY="${id}"
}

confluence-import() {
    emulate -L zsh -o extended_glob
    local REPLY
    local -a reply

    local -a o_url o_parent o_title o_message o_email o_noprune o_recursive o_help
    zparseopts -D -E -F -- \
        u:=o_url -url:=o_url -page-id:=o_url \
        p:=o_parent -parent:=o_parent \
        t:=o_title -title:=o_title \
        m:=o_message -message:=o_message \
        e:=o_email -email:=o_email \
        r=o_recursive -recursive=o_recursive \
        -no-prune=o_noprune \
        h=o_help -help=o_help || return 8

    if (( ${#o_help} || $# == 0 )); then
        cat <<'EOF'
usage: confluence-import <zip>... [-u <URL かページ ID> | -p <親の URL かページ ID>] [-r]
                         [-t <タイトル>] [-m <版のメッセージ>] [-e <メールアドレス>] [--no-prune]
  zip（page.xhtml と図）の中身で、Confluence のページを更新する
  1. 本文が参照している図を添付に反映する。中身が同じ図は上げない（添付のコメントの sha256 で比べる）
  2. この関数が上げた図（コメントが sha256: で始まる）のうち、本文が参照しなくなったものを削除する（--no-prune で無効）
  3. 本文を page.xhtml で丸ごと置き換える。タイトルは -t を付けなければ今のまま
  取り込む先
    -u も -p もなし  zip の名前の先頭の数字（<ページ ID>_<名前>.zip）のページ
    -u               指定したページ（zip が 1 つのときだけ）
    -p               指定したページの子。同じタイトルの子があれば更新し、なければ作る
                     タイトルは -t、なければ zip の中の page.json、なければ zip の名前（先頭の <数字>_ を除く）
  -r  zip と同じ名前のフォルダがあれば、その中の zip をそのページの子として取り込む（孫以下も同じ）
  -t は zip が 1 つのときだけ使える
  zip は $TMPDIR の下に展開し、終わったら（失敗しても）消す
EOF
        (( ${#o_help} )) && return 0
        return 8
    fi

    local z
    local -a zips
    for z in "$@"; do
        if [[ ! -f "${z}" ]]; then
            __rayrc_cf_err "ファイルがありません：${z}"
            return 8
        fi
        z="${z:A}"
        if [[ "${z:e}" != zip ]]; then
            __rayrc_cf_err "zip を指定してください：${z}"
            return 8
        fi
        zips+=("${z}")
    done
    if (( ${#o_url} && ${#o_parent} )); then
        __rayrc_cf_err "-u と -p は一緒に使えません"
        return 8
    fi
    if (( ${#zips} > 1 && ( ${#o_url} || ${#o_title} ) )); then
        __rayrc_cf_err "-u と -t は zip が 1 つのときだけ使えます"
        return 8
    fi
    __rayrc_cf_need curl jq unzip || return 8
    (( ${+commands[sha256sum]} )) || __rayrc_cf_need shasum || return 8

    ## 取り込む先：-p なら親の子、そうでなければ -u か zip の名前のページ ID のページ
    local site=''
    local parent=''
    local url=''
    local -a ids
    if (( ${#o_parent} )); then
        __rayrc_cf_resolve_page "${o_parent[-1]}" || return 8
        site="${reply[1]}"
        parent="${reply[2]}"
    else
        url="${o_url[-1]}"
        if [[ -z "${url}" && ${#zips} -eq 1 && "${zips[1]:t}" != [0-9]##_* ]]; then
            read -r "url?反映先のページの URL か ID（zip の名前を <ページ ID>_<名前>.zip にすれば省略できる）: " || return 8
        fi
        if [[ -n "${url}" ]]; then
            __rayrc_cf_resolve_page "${url}" || return 8
            site="${reply[1]}"
            ids=("${reply[2]}")
        else
            for z in "${zips[@]}"; do
                if [[ "${z:t}" != (#b)([0-9]##)_* ]]; then
                    __rayrc_cf_err "zip の名前からページ ID が読めません（<ページ ID>_<名前>.zip にするか、-p で親を指定する）：${z}"
                    return 8
                fi
                ids+=("${match[1]}")
            done
            __rayrc_cf_site || return 8
            site="${REPLY}"
        fi
    fi
    __rayrc_cf_auth "${site#https://}" "${o_email[-1]}" || return 8
    local auth="${REPLY}"
    local message="${o_message[-1]:-confluence-import で更新}"
    local prune=true
    local recursive=false
    (( ${#o_noprune} )) && prune=false
    (( ${#o_recursive} )) && recursive=true

    local i
    for (( i = 1; i <= ${#zips}; i++ )); do
        __rayrc_cf_import_page "${auth}" "${site}" "${zips[i]}" "${ids[i]}" "${parent}" \
            "${o_title[-1]}" "${message}" "${prune}" "${recursive}" || return 8
    done
}

# ---- 書き出し ----

confluence-export() {
    emulate -L zsh -o extended_glob
    local REPLY
    local -a reply

    local -a o_out o_email o_force o_recursive o_help
    zparseopts -D -E -F -- \
        o:=o_out -output-dir:=o_out \
        e:=o_email -email:=o_email \
        f=o_force -force=o_force \
        r=o_recursive -recursive=o_recursive \
        h=o_help -help=o_help || return 8

    if (( ${#o_help} || $# != 1 )); then
        cat <<'EOF'
usage: confluence-export <URL かページ ID> [-o <出力フォルダ>] [-e <メールアドレス>] [-f] [-r]
  Confluence のページを zip に書き出す（page.xhtml・page.json・添付ファイル）
  zip の名前は「<ページ ID>_<タイトル>.zip」。そのまま confluence-import に渡せる
  - page.xhtml：本文（ストレージ形式）
  - page.json ：ID、タイトル、版、スペース、書き出した日時、添付の一覧（-r なら子の一覧も）
  - 添付ファイル：ページのすべての添付（今の版）
  -o を省略するとカレントディレクトリに書き出す。すでにあれば -f で上書きする
  -r  子孫のページも書き出す。子は zip と同じ名前のフォルダに入れる（孫以下も同じ）
      confluence-import -r に渡すと、同じ入れ子で取り込める
EOF
        (( ${#o_help} )) && return 0
        return 8
    fi

    local outdir="${o_out[-1]:-${PWD}}"
    if [[ ! -d "${outdir}" ]]; then
        __rayrc_cf_err "出力フォルダがありません：${outdir}"
        return 8
    fi
    __rayrc_cf_need curl jq zip || return 8

    __rayrc_cf_resolve_page "$1" || return 8
    local site="${reply[1]}"
    local id="${reply[2]}"
    __rayrc_cf_auth "${site#https://}" "${o_email[-1]}" || return 8
    local auth="${REPLY}"
    local force=false
    local recursive=false
    (( ${#o_force} )) && force=true
    (( ${#o_recursive} )) && recursive=true

    __rayrc_cf_export_page "${auth}" "${site}" "${id}" "${outdir:A}" "${force}" "${recursive}"
}

## __rayrc_cf_export_page <認証> <サイト> <ページ ID> <出力フォルダ> <force> <recursive>
## recursive が true なら、子のページを zip と同じ名前のフォルダに書き出す（孫以下も同じ）
__rayrc_cf_export_page() {
    emulate -L zsh -o extended_glob
    local auth="$1"
    local site="$2"
    local id="$3"
    local outdir="$4"
    local force="$5"
    local recursive="$6"
    local api="${site}/wiki/rest/api"

    __rayrc_cf_curl "${auth}" '' "${api}/content/${id}?expand=body.storage,version,space" || return 8
    local info="${REPLY}"
    local title version
    title="$(jq -r '.title' <<<"${info}")" || return 8
    version="$(jq -r '.version.number' <<<"${info}")" || return 8

    local unsafe='[\\/:*?"<>|[:space:]]##'
    local safe="${title//${~unsafe}/_}"
    safe="${${safe##_##}%%_##}"
    safe="${safe[1,60]}"
    local out="${outdir}/${id}_${safe}.zip"
    if [[ -e "${out}" && "${force}" != true ]]; then
        __rayrc_cf_err "すでにあります（上書きするときは -f）：${out}"
        return 8
    fi
    print -r -- "ページ：${title}（版 ${version}、ID ${id}）"

    local kids='[]'
    if [[ "${recursive}" == true ]]; then
        __rayrc_cf_list "${auth}" "${api}/content/${id}/child/page?limit=100" || return 8
        kids="${REPLY}"
    fi

    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/confluence-export_XXXXXXXX")" || return 8
    {
        jq -j '.body.storage.value' <<<"${info}" >"${work}/page.xhtml" || return 8

        __rayrc_cf_list "${auth}" "${api}/content/${id}/child/attachment?limit=100&expand=metadata" || return 8
        local atts="${REPLY}"
        local t dl
        while IFS=$'\t' read -r t dl; do
            print -r -- "添付：${t}"
            __rayrc_cf_curl "${auth}" "${work}/${t}" "${site}/wiki${dl}" || return 8
        done < <(jq -r '.[] | [.title, ._links.download] | @tsv' <<<"${atts}")

        jq --arg id "${id}" --arg site "${site}" --arg at "$(date +%Y-%m-%dT%H:%M:%S)" \
            --argjson atts "${atts}" --argjson kids "${kids}" --argjson rec "${recursive}" \
            '{id: $id, title: .title, version: .version.number, space: .space.key,
              site: $site, exportedAt: $at,
              attachments: [$atts[] | {title, mediaType: .extensions.mediaType, comment: .metadata.comment}]}
             + (if $rec then {children: [$kids[] | {id, title}]} else {} end)' \
            <<<"${info}" >"${work}/page.json" || return 8

        [[ -e "${out}" ]] && { rm -f -- "${out}" || return 8; }
        ( cd -- "${work}" && zip -qrX "${out}" . ) || return 8
        print -r -- "完了（版 ${version}、添付 $(jq 'length' <<<"${atts}") 件）：${out}"
    } always {
        rm -rf -- "${work}"
    }

    # 子（zip と同じ名前のフォルダに書き出す）
    if [[ "${recursive}" == true ]] && (( $(jq 'length' <<<"${kids}") )); then
        local kid
        mkdir -p -- "${out:r}" || return 8
        for kid in ${(f)"$(jq -r '.[].id' <<<"${kids}")"}; do
            __rayrc_cf_export_page "${auth}" "${site}" "${kid}" "${out:r}" "${force}" true || return 8
        done
    fi
}
