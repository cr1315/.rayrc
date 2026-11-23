#!/usr/bin/env zsh
######################################################################
##
## Confluence Cloud のページを zip で取り込む・書き出す関数（main.ps1 の zsh 版）
##
##   confluence-import 330137615_promote.zip     # zip の中身でページを更新する
##   confluence-export 330137615                 # ページを zip に書き出す（URL でもよい）
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

## __rayrc_cf_attachments <認証> <API の URL> <ページ ID> → REPLY=<添付の JSON 配列>
__rayrc_cf_attachments() {
    emulate -L zsh
    local all='[]'
    local start=0
    local page
    while true; do
        __rayrc_cf_curl "$1" '' "$2/content/$3/child/attachment?limit=100&start=${start}&expand=metadata" || return 8
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

confluence-import() {
    emulate -L zsh -o extended_glob
    local REPLY
    local -a reply

    local -a o_url o_title o_message o_email o_noprune o_help
    zparseopts -D -E -F -- \
        u:=o_url -url:=o_url -page-id:=o_url \
        t:=o_title -title:=o_title \
        m:=o_message -message:=o_message \
        e:=o_email -email:=o_email \
        -no-prune=o_noprune \
        h=o_help -help=o_help || return 8

    if (( ${#o_help} || $# != 1 )); then
        cat <<'EOF'
usage: confluence-import <zip> [-u <URL かページ ID>] [-t <タイトル>] [-m <版のメッセージ>] [-e <メールアドレス>] [--no-prune]
  zip（page.xhtml と図）の中身で、Confluence のページを更新する
  1. 本文が参照している図を添付に反映する。中身が同じ図は上げない（添付のコメントの sha256 で比べる）
  2. この関数が上げた図（コメントが sha256: で始まる）のうち、本文が参照しなくなったものを削除する（--no-prune で無効）
  3. 本文を page.xhtml で丸ごと置き換える。タイトルは -t を付けなければ今のまま
  -u を省略すると、zip の名前の先頭の数字（<ページ ID>_<名前>.zip）をページ ID にする
  zip は $TMPDIR の下に展開し、終わったら（失敗しても）消す
EOF
        (( ${#o_help} )) && return 0
        return 8
    fi

    local zip="$1"
    if [[ ! -f "${zip}" ]]; then
        __rayrc_cf_err "ファイルがありません：${zip}"
        return 8
    fi
    zip="${zip:A}"
    if [[ "${zip:e}" != zip ]]; then
        __rayrc_cf_err "zip を指定してください：${zip}"
        return 8
    fi
    __rayrc_cf_need curl jq unzip || return 8
    (( ${+commands[sha256sum]} )) || __rayrc_cf_need shasum || return 8

    local url="${o_url[-1]}"
    if [[ -z "${url}" ]]; then
        if [[ "${zip:t}" == (#b)([0-9]##)_* ]]; then
            url="${match[1]}"
        else
            read -r "url?反映先のページの URL か ID（zip の名前を <ページ ID>_<名前>.zip にすれば省略できる）: " || return 8
        fi
    fi
    __rayrc_cf_resolve_page "${url}" || return 8
    local site="${reply[1]}"
    local id="${reply[2]}"
    local api="${site}/wiki/rest/api"
    __rayrc_cf_auth "${site#https://}" "${o_email[-1]}" || return 8
    local auth="${REPLY}"
    local message="${o_message[-1]:-confluence-import で更新}"

    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/confluence-import_XXXXXXXX")" || return 8
    {
        unzip -q "${zip}" -d "${work}" || return 8
        local -a found
        found=("${work}"/**/page.xhtml(N.))
        if (( ${#found} != 1 )); then
            __rayrc_cf_err "zip の中に page.xhtml がちょうど 1 つ必要です（見つかった数：${#found}）"
            return 8
        fi
        local dir="${found[1]:h}"

        __rayrc_cf_curl "${auth}" '' "${api}/content/${id}?expand=version" || return 8
        local cur_title version
        cur_title="$(jq -r '.title' <<<"${REPLY}")" || return 8
        version="$(jq -r '.version.number' <<<"${REPLY}")" || return 8
        local title="${o_title[-1]:-${cur_title}}"
        print -r -- "ページ：${cur_title}（版 ${version}、ID ${id}）"

        # 図
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

        __rayrc_cf_attachments "${auth}" "${api}" "${id}" || return 8
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
        if (( ! ${#o_noprune} )); then
            for t in "${(@k)r_id}"; do
                if [[ "${r_comment[$t]}" == sha256:* ]] && (( ! ${wanted[(Ie)$t]} )); then
                    print -r -- "図：${t}（本文が参照しなくなったので削除）"
                    __rayrc_cf_curl "${auth}" '' -X DELETE "${api}/content/${r_id[$t]}" || return 8
                fi
            done
        fi

        # 本文
        local json="${work}/.payload.json"
        jq -n --arg id "${id}" --arg title "${title}" --arg msg "${message}" \
            --argjson ver "$(( version + 1 ))" --rawfile body "${found[1]}" \
            '{id: $id, type: "page", title: $title,
              version: {number: $ver, message: $msg},
              body: {storage: {value: ($body | ltrimstr("\ufeff")), representation: "storage"}}}' \
            >"${json}" || return 8
        __rayrc_cf_curl "${auth}" '' -X PUT -H "Content-Type: application/json; charset=utf-8" \
            --data-binary "@${json}" "${api}/content/${id}" || return 8
        print -r -- "完了（版 $(( version + 1 ))）：${site}/wiki/pages/viewpage.action?pageId=${id}"
    } always {
        rm -rf -- "${work}"
    }
}

# ---- 書き出し ----

confluence-export() {
    emulate -L zsh -o extended_glob
    local REPLY
    local -a reply

    local -a o_out o_email o_force o_help
    zparseopts -D -E -F -- \
        o:=o_out -output-dir:=o_out \
        e:=o_email -email:=o_email \
        f=o_force -force=o_force \
        h=o_help -help=o_help || return 8

    if (( ${#o_help} || $# != 1 )); then
        cat <<'EOF'
usage: confluence-export <URL かページ ID> [-o <出力フォルダ>] [-e <メールアドレス>] [-f]
  Confluence のページを zip に書き出す（page.xhtml・page.json・添付ファイル）
  zip の名前は「<ページ ID>_<タイトル>.zip」。そのまま confluence-import に渡せる
  - page.xhtml：本文（ストレージ形式）
  - page.json ：ID、タイトル、版、スペース、書き出した日時、添付の一覧
  - 添付ファイル：ページのすべての添付（今の版）
  -o を省略するとカレントディレクトリに書き出す。すでにあれば -f で上書きする
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
    local api="${site}/wiki/rest/api"
    __rayrc_cf_auth "${site#https://}" "${o_email[-1]}" || return 8
    local auth="${REPLY}"

    __rayrc_cf_curl "${auth}" '' "${api}/content/${id}?expand=body.storage,version,space" || return 8
    local info="${REPLY}"
    local title version
    title="$(jq -r '.title' <<<"${info}")" || return 8
    version="$(jq -r '.version.number' <<<"${info}")" || return 8

    local unsafe='[\\/:*?"<>|[:space:]]##'
    local safe="${title//${~unsafe}/_}"
    safe="${${safe##_##}%%_##}"
    safe="${safe[1,60]}"
    local out="${outdir:A}/${id}_${safe}.zip"
    if [[ -e "${out}" ]] && (( ! ${#o_force} )); then
        __rayrc_cf_err "すでにあります（上書きするときは -f）：${out}"
        return 8
    fi

    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/confluence-export_XXXXXXXX")" || return 8
    {
        jq -j '.body.storage.value' <<<"${info}" >"${work}/page.xhtml" || return 8

        __rayrc_cf_attachments "${auth}" "${api}" "${id}" || return 8
        local atts="${REPLY}"
        local t dl
        while IFS=$'\t' read -r t dl; do
            print -r -- "添付：${t}"
            __rayrc_cf_curl "${auth}" "${work}/${t}" "${site}/wiki${dl}" || return 8
        done < <(jq -r '.[] | [.title, ._links.download] | @tsv' <<<"${atts}")

        jq --arg id "${id}" --arg site "${site}" --arg at "$(date +%Y-%m-%dT%H:%M:%S)" \
            --argjson atts "${atts}" \
            '{id: $id, title: .title, version: .version.number, space: .space.key,
              site: $site, exportedAt: $at,
              attachments: [$atts[] | {title, mediaType: .extensions.mediaType, comment: .metadata.comment}]}' \
            <<<"${info}" >"${work}/page.json" || return 8

        [[ -e "${out}" ]] && { rm -f -- "${out}" || return 8; }
        ( cd -- "${work}" && zip -qrX "${out}" . ) || return 8
        print -r -- "完了（版 ${version}、添付 $(jq 'length' <<<"${atts}") 件）：${out}"
    } always {
        rm -rf -- "${work}"
    }
}
