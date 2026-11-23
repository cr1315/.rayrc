#!/usr/bin/env bash
######################################################################
##
## lfscp の共通部品（lfscp から source される。形式ハンドラーからも使う）
##   名前付け・manifest・リポジトリの割り出し・サイズ表記・未コミットの要約
##
######################################################################

## バイト数を 12.3MB のような表記にする
__lfscp_human_size() {
    awk -v b="$1" 'BEGIN {
        split("B KB MB GB TB", u, " ")
        i = 1
        while (b >= 1024 && i < 5) { b /= 1024; i++ }
        if (i == 1) printf "%dB", b; else printf "%.1f%s", b, u[i]
    }'
}

## ファイルのサイズ（バイト）
__lfscp_file_bytes() {
    echo "$(($(wc -c <"$1")))"
}

## パスを絶対パスにする。フォルダはリンクを解き、最後の要素がリンクならリンクのまま残す
__lfscp_abs_path() {
    local p="$1" dir base
    p="${p%"${p##*[!/]}"}"
    [[ -n "$p" ]] || p="/"
    if [[ "$p" == "/" ]]; then
        echo "/"
        return
    fi
    dir="$(dirname -- "$p")"
    base="$(basename -- "$p")"
    dir="$(cd -P -- "$dir" && pwd -P)" || return 1
    if [[ "$dir" == "/" ]]; then
        echo "/${base}"
    else
        echo "${dir}/${base}"
    fi
}

## パスからリポジトリの最上位を割り出して表示する。リポジトリでなければ 1 を返す
__lfscp_resolve_repo() {
    local p="$1" d top

    ## 直下に .git がある（worktree やサブモジュールの .git ファイルも含む）
    if [[ -d "$p" && -e "$p/.git" ]]; then
        (cd -P -- "$p" && pwd -P)
        return
    fi

    if [[ -d "$p" ]]; then
        d="$p"
    elif [[ -e "$p" ]]; then
        d="$(dirname -- "$p")"
    else
        return 1
    fi

    top="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null)" || return 1
    [[ -n "$top" ]] || return 1
    (cd -P -- "$top" && pwd -P)
}

## ブランチ名（detached HEAD なら短い sha）を表示する
__lfscp_git_branch() {
    local branch
    branch="$(git -C "$1" branch --show-current 2>/dev/null || true)"
    if [[ -z "$branch" ]]; then
        branch="$(git -C "$1" rev-parse --short HEAD 2>/dev/null || echo '（不明）')"
    fi
    echo "$branch"
}

## 未コミットの変更（未追跡を含む）を件数と先頭 5 件で表示する。無ければ何も出さない
##   usage: __lfscp_git_dirty_summary <repo> <何に含まれないか（例：バンドル）>
__lfscp_git_dirty_summary() {
    local repo="$1" what="$2" status_out count=0 shown=0 line

    status_out="$(git -C "$repo" -c core.quotepath=false status --short 2>/dev/null || true)"
    [[ -n "$status_out" ]] || return 0

    while IFS= read -r line; do
        count=$((count + 1))
    done <<<"$status_out"
    echo "  未コミットの変更：${count} 件（${what}には含まれない）"
    while IFS= read -r line; do
        if ((shown >= 5)); then
            echo "    ..."
            break
        fi
        echo "    ${line}"
        shown=$((shown + 1))
    done <<<"$status_out"
}

## コマンドを実行し、標準エラーは失敗したとき（終了コードが 0 以外）だけ字下げして見せる
##   終了コードはそのまま返す
__lfscp_run_quiet() {
    local err="${LFSCP_SESSION}/meta/err" rc=0 line
    "$@" >/dev/null 2>"$err" || rc=$?
    if ((rc != 0)); then
        while IFS= read -r line; do
            echo "    ${line}" >&2
        done <"$err"
    fi
    rm -f -- "$err"
    return "$rc"
}

## 先頭の . を外す（.rayrc → rayrc）
__lfscp_strip_dots() {
    local s="$1"
    echo "${s#"${s%%[!.]*}"}"
}

######################################################################
## manifest.tsv：名前<TAB>形式<TAB>元の絶対パス
##   名前の衝突と置き換えの判断にだけ使う（一覧は out/ の実物から作る）
######################################################################

## 同じ（形式, 元）で前に作った名前を表示する。無ければ何も出さない
__lfscp_manifest_lookup() {
    local fmt="$1" src="$2" manifest="${LFSCP_SESSION}/meta/manifest.tsv" n f s
    [[ -f "$manifest" ]] || return 0
    while IFS=$'\t' read -r n f s; do
        if [[ "$f" == "$fmt" && "$s" == "$src" ]]; then
            echo "$n"
        fi
    done <"$manifest"
}

## 名前<TAB>形式<TAB>元 を記録する。同じ（形式, 元）と同じ名前の古い行は消す
##   （かごで消した名前を別の元が使ったとき、古い行が新しいファイルを指さないように）
__lfscp_manifest_put() {
    local name="$1" fmt="$2" src="$3"
    local manifest="${LFSCP_SESSION}/meta/manifest.tsv" tmp n f s
    tmp="${manifest}.tmp"
    : >"$tmp"
    if [[ -f "$manifest" ]]; then
        while IFS=$'\t' read -r n f s; do
            if [[ "$n" == "$name" ]] || [[ "$f" == "$fmt" && "$s" == "$src" ]]; then
                continue
            fi
            printf '%s\t%s\t%s\n' "$n" "$f" "$s" >>"$tmp"
        done <"$manifest"
    fi
    printf '%s\t%s\t%s\n' "$name" "$fmt" "$src" >>"$tmp"
    mv -f -- "$tmp" "$manifest"
}

## out/ の中で空いている名前を表示する
##   usage: __lfscp_pick_name <stem> <ext> <親フォルダ名> <空いているとみなす名前（置き換え対象）>
##   <stem><ext> → <親>_<stem><ext> → <親>_<stem>_2<ext> → ...
__lfscp_pick_name() {
    local stem="$1" ext="$2" parent="$3" reserved="$4" out="${LFSCP_SESSION}/out" name i

    __lfscp_name_free() {
        [[ "$1" == "$reserved" || ! -e "${out}/$1" && ! -L "${out}/$1" ]]
    }

    name="${stem}${ext}"
    if ! __lfscp_name_free "$name"; then
        name="${parent}_${stem}${ext}"
        i=2
        while ! __lfscp_name_free "$name"; do
            name="${parent}_${stem}_${i}${ext}"
            i=$((i + 1))
        done
    fi
    unset -f __lfscp_name_free
    echo "$name"
}
