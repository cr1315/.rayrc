#!/usr/bin/env zsh
######################################################################
##
## ③ ページ：ページのフォルダと Confluence のページ 1 枚を行き来させる
##   ページのフォルダ（zip を展開したもの）
##     page.xhtml  本文（ストレージ形式）
##     page.json   id、title、version、space、site、exportedAt、attachments
##                 （children は ② 一括が足す）
##     <図>        本文が ri:attachment で参照するファイル
##   言われたページを、言われたとおりに読み書きする。zip・入れ子・どのページに入れるかは知らない。
##   層の分け方は リファクタリング.md を参照。
##
######################################################################

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

## __rayrc_cf_html_decode <文字列> → REPLY（&amp; や &#12354; を戻す）
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

## __rayrc_cf_page_info <認証> <サイト> <ページ ID> → REPLY=<ページの JSON（本文・版・スペース付き）>
__rayrc_cf_page_info() {
    __rayrc_cf_curl "$1" '' "$2/wiki/rest/api/content/$3?expand=body.storage,version,space"
}

## __rayrc_cf_page_pull <認証> <サイト> <ページの JSON> <フォルダ> → REPLY=<添付の数>
## ページを、空のフォルダに書き出す（page.xhtml・page.json・添付）
__rayrc_cf_page_pull() {
    emulate -L zsh
    local auth="$1"
    local site="$2"
    local info="$3"
    local dir="$4"
    local id
    id="$(jq -r '.id' <<<"${info}")" || return 8

    jq -j '.body.storage.value' <<<"${info}" >"${dir}/page.xhtml" || return 8

    __rayrc_cf_list "${auth}" "${site}/wiki/rest/api/content/${id}/child/attachment?limit=100&expand=metadata" || return 8
    local atts="${REPLY}"
    local t dl
    while IFS=$'\t' read -r t dl; do
        print -r -- "添付：${t}"
        __rayrc_cf_curl "${auth}" "${dir}/${t}" "${site}/wiki${dl}" || return 8
    done < <(jq -r '.[] | [.title, ._links.download] | @tsv' <<<"${atts}")

    jq --arg site "${site}" --arg at "$(date +%Y-%m-%dT%H:%M:%S)" --argjson atts "${atts}" \
        '{id: .id, title: .title, version: .version.number, space: .space.key,
          site: $site, exportedAt: $at,
          attachments: [$atts[] | {title, mediaType: .extensions.mediaType, comment: .metadata.comment}]}' \
        <<<"${info}" >"${dir}/page.json" || return 8

    REPLY="$(jq 'length' <<<"${atts}")"
}

## __rayrc_cf_page_push <認証> <サイト> <フォルダ> <update|create> <ページ ID|親 ID> <タイトル> <版のメッセージ> <prune>
##   update：ページ ID のページの本文を置き換える。タイトルが空なら今のまま
##   create：親 ID の下にページを作る（タイトルは必ず要る）
## どちらも、本文が参照する図を添付に反映する。
##   - 中身が同じ図は上げない（添付のコメントの sha256 で比べる）
##   - prune が true なら、この関数が上げた図（コメントが sha256: で始まる）のうち、本文が参照しなくなったものを消す
## → REPLY=<ページ ID>
__rayrc_cf_page_push() {
    emulate -L zsh -o extended_glob
    local auth="$1"
    local site="$2"
    local dir="$3"
    local mode="$4"
    local target="$5"
    local title="$6"
    local message="$7"
    local prune="$8"
    local api="${site}/wiki/rest/api"
    local body="${dir}/page.xhtml"
    local json="${dir}/.payload.json"

    # 図（ページに書き込む前に、本文が参照している図がそろっているかを確かめる）
    local w name file comment
    local -a wanted decoded missing
    for w in ${(f)"$(grep -oE 'ri:attachment ri:filename="[^"]+"' -- "${body}")"}; do
        w="${${w#ri:attachment ri:filename=\"}%\"}"
        __rayrc_cf_html_decode "${w}"
        decoded+=("${REPLY}")
    done
    wanted=("${(@u)decoded}")
    for name in "${wanted[@]}"; do
        [[ -e "${dir}/${name}" ]] || missing+=("${name}")
    done
    if (( ${#missing} )); then
        __rayrc_cf_err "本文が参照している図がありません：${(j:, :)missing}"
        return 8
    fi

    # ページ（作るときは本文ごと作る。図はこのあと上げる）
    local id version
    case "${mode}" in
        update)
            id="${target}"
            __rayrc_cf_curl "${auth}" '' "${api}/content/${id}?expand=version" || return 8
            local cur_title
            cur_title="$(jq -r '.title' <<<"${REPLY}")" || return 8
            version="$(jq -r '.version.number' <<<"${REPLY}")" || return 8
            [[ -n "${title}" ]] || title="${cur_title}"
            print -r -- "ページ：${cur_title}（版 ${version}、ID ${id}）"
            ;;
        create)
            __rayrc_cf_curl "${auth}" '' "${api}/content/${target}?expand=space" || return 8
            local space
            space="$(jq -r '.space.key' <<<"${REPLY}")" || return 8
            jq -n --arg title "${title}" --arg space "${space}" --arg parent "${target}" \
                --rawfile body "${body}" \
                '{type: "page", title: $title, space: {key: $space}, ancestors: [{id: $parent}],
                  body: {storage: {value: ($body | if (explode[0] == 65279) then .[1:] else . end),
                                   representation: "storage"}}}' \
                >"${json}" || return 8
            __rayrc_cf_curl "${auth}" '' -X POST -H "Content-Type: application/json; charset=utf-8" \
                --data-binary "@${json}" "${api}/content" || return 8
            id="$(jq -r '.id' <<<"${REPLY}")" || return 8
            print -r -- "ページ：${title}（新しく作成、ID ${id}、親 ID ${target}）"
            ;;
        *)
            __rayrc_cf_err "update か create を指定してください：${mode}"
            return 8
            ;;
    esac

    # 図
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
    if [[ "${mode}" == create ]]; then
        print -r -- "完了（新しく作成）：${site}/wiki/pages/viewpage.action?pageId=${id}"
    else
        jq -n --arg id "${id}" --arg title "${title}" --arg msg "${message}" \
            --argjson ver "$(( version + 1 ))" --rawfile body "${body}" \
            '{id: $id, type: "page", title: $title,
              version: {number: $ver, message: $msg},
              body: {storage: {value: ($body | if (explode[0] == 65279) then .[1:] else . end),
                               representation: "storage"}}}' \
            >"${json}" || return 8
        __rayrc_cf_curl "${auth}" '' -X PUT -H "Content-Type: application/json; charset=utf-8" \
            --data-binary "@${json}" "${api}/content/${id}" || return 8
        print -r -- "完了（版 $(( version + 1 ))）：${site}/wiki/pages/viewpage.action?pageId=${id}"
    fi
    REPLY="${id}"
}
