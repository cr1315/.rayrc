#!/usr/bin/env bash
######################################################################
## git-bundle（tb）：リポジトリの全 ref の履歴を 1 ファイルの bundle にする
##   元   選んだものが属するリポジトリの最上位
##   名前 <repo>.bundle
##   検証 git bundle verify
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

__lfscp_fmt_requires() {
    echo git
}

__lfscp_fmt_resolve() {
    if ! __lfscp_resolve_repo "$1"; then
        echo "リポジトリではない" >&2
        return 1
    fi
}

__lfscp_fmt_name() {
    printf '%s\t%s\n' "$(basename -- "$1")" ".bundle"
}

__lfscp_fmt_info() {
    echo "  ブランチ：$(__lfscp_git_branch "$1")"
    __lfscp_git_dirty_summary "$1" "バンドル"
}

## コミットが 1 つもないリポジトリは、空のバンドルを作れないのでここで失敗する
__lfscp_fmt_create() {
    __lfscp_run_quiet git -C "$1" bundle create "$2" --all
}

## verify はリポジトリの中で動かす必要があるので、元（$2）を使う
__lfscp_fmt_verify() {
    __lfscp_run_quiet git -C "$2" bundle verify "$1"
}
