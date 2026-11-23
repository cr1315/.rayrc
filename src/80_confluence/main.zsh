#!/usr/bin/env zsh
######################################################################
##
## Confluence Cloud のページを zip で取り込む・書き出す関数（main.ps1 の zsh 版）
##
##   confluence-import 330137615_promote.zip     # zip の中身でページを更新する
##   confluence-import -p 330137615 a.zip b.zip  # 親の子として取り込む（同じタイトルの子があれば更新、なければ作る）
##   confluence-export 330137615                 # ページを zip に書き出す（URL でもよい）
##   confluence-export -r 330137615              # 子孫のページも書き出す
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
## 使うコマンド：curl、jq、zip、unzip、sha256sum（なければ shasum）
##
## 層（refactoring.md を参照）
##   ① main.zsh  CLI：オプションを読んで確かめ、② に渡す
##   ② bulk.zsh  一括：zip とフォルダの配置、入れ子、どのページに入れるか、タイトル
##   ③ page.zsh  ページ：ページのフォルダと Confluence のページ 1 枚を行き来させる
##   ④ api.zsh   共通：認証、curl、一覧、URL の読み取り
##
######################################################################

__rayrc_main() {
    __rayrc_module_common_setup

    source "${__rayrc_ctl_dir}/api.zsh"
    source "${__rayrc_ctl_dir}/page.zsh"
    source "${__rayrc_ctl_dir}/bulk.zsh"
}

__rayrc_main
unset -f __rayrc_main

# ---- 取り込み ----

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
  3. 本文を page.xhtml で丸ごと置き換える。先頭の <title> はタイトルの場所なので、本文からは除く
  タイトル（上から順に、最初に見つかったもの）
    -t → page.xhtml の先頭の <title> → page.json の title
       → ページを更新するなら今のまま、親の下に入れるなら zip の名前（先頭の <数字>_ を除く）
  取り込む先
    -u も -p もなし  zip の名前の先頭の数字（<ページ ID>_<名前>.zip）のページ
    -u               指定したページ（zip が 1 つのときだけ）
    -p               指定したページの子。上から順に
                     page.json の site が同じで、その id の子があれば更新（タイトルを変えても同じページ）
                     → 同じタイトルの子があれば更新 → なければ作る
  -r  zip と同じ名前のフォルダがあれば、その中の zip をそのページの子として取り込む（-p と同じ決まり。孫以下も同じ）
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

    ## 取り込む先：-p なら親の下（parent）、そうでなければ -u か zip の名前のページ（page）
    local site=''
    local kind=page
    local url=''
    local -a refs
    if (( ${#o_parent} )); then
        __rayrc_cf_resolve_page "${o_parent[-1]}" || return 8
        site="${reply[1]}"
        kind=parent
        for z in "${zips[@]}"; do
            refs+=("${reply[2]}")
        done
    else
        url="${o_url[-1]}"
        if [[ -z "${url}" && ${#zips} -eq 1 ]] && ! __rayrc_cf_zip_id "${zips[1]}"; then
            read -r "url?反映先のページの URL か ID（zip の名前を <ページ ID>_<名前>.zip にすれば省略できる）: " || return 8
        fi
        if [[ -n "${url}" ]]; then
            __rayrc_cf_resolve_page "${url}" || return 8
            site="${reply[1]}"
            refs=("${reply[2]}")
        else
            for z in "${zips[@]}"; do
                if ! __rayrc_cf_zip_id "${z}"; then
                    __rayrc_cf_err "zip の名前からページ ID が読めません（<ページ ID>_<名前>.zip にするか、-p で親を指定する）：${z}"
                    return 8
                fi
                refs+=("${REPLY}")
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
        __rayrc_cf_bulk_import "${auth}" "${site}" "${zips[i]}" "${kind}" "${refs[i]}" \
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
  - page.xhtml：本文（ストレージ形式）。先頭に <title>タイトル</title> の 1 行を足す（取り込むときにタイトルになる）
  - page.json ：ID、タイトル、版、スペース、サイト、書き出した日時、添付の一覧（-r なら子の一覧も）
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

    __rayrc_cf_bulk_export "${auth}" "${site}" "${id}" "${outdir:A}" "${force}" "${recursive}"
}
