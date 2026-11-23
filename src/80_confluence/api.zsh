#!/usr/bin/env zsh
######################################################################
##
## ④ 共通：認証、curl、ページ送りのある一覧、URL の読み取り
##   Confluence の REST API を呼ぶための道具だけを置く。ページの中身・zip・入れ子は知らない。
##   層の分け方は refactoring.md を参照。
##
######################################################################

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

## __rayrc_cf_children <認証> <サイト> <ページ ID> → REPLY=<直下の子の JSON 配列（Confluence での並び順）>
__rayrc_cf_children() {
    __rayrc_cf_list "$1" "$2/wiki/rest/api/content/$3/child/page?limit=100"
}
