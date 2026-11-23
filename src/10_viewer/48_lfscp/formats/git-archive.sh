#!/usr/bin/env bash
######################################################################
## git-archive（ta）：HEAD のツリー（追跡ファイルのみ、.git なし）を tar.gz にする
##   元   選んだものが属するリポジトリの最上位（フォルダ・サブフォルダ・ファイルのどれでも）
##   名前 <repo>-<短い sha>.tar.gz。中身は <repo>-<sha>/ の 1 段に包む（GitHub と同じ）
##   検証 gzip -t
##   未コミット・未追跡、サブモジュールの中身、LFS の実体は入らない（あれば警告）
##   名前に sha が入るので、コミット後に押し直すと名前が変わる。古い方は（形式, 元）で探して置き換える
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

__lfscp_fmt_requires() {
    echo git gzip
}

__lfscp_fmt_resolve() {
    local top
    if ! top="$(__lfscp_resolve_repo "$1")"; then
        echo "リポジトリではない" >&2
        return 1
    fi
    if ! git -C "$top" rev-parse -q --verify HEAD >/dev/null; then
        echo "コミットが無い" >&2
        return 1
    fi
    echo "$top"
}

__lfscp_fmt_name() {
    printf '%s-%s\t%s\n' "$(basename -- "$1")" "$(git -C "$1" rev-parse --short HEAD)" ".tar.gz"
}

__lfscp_fmt_info() {
    local repo="$1" n
    echo "  ブランチ：$(__lfscp_git_branch "$repo")"
    __lfscp_git_dirty_summary "$repo" "アーカイブ"
    if git -C "$repo" cat-file -e HEAD:.gitmodules 2>/dev/null; then
        echo "  警告：サブモジュールの中身は入らない（.gitmodules がある）"
    fi
    n="$(git -C "$repo" ls-files -- ':(attr:filter=lfs)' 2>/dev/null | wc -l)"
    if ((n > 0)); then
        echo "  警告：LFS の実体は入らない（ポインタだけ。filter=lfs が ${n} 件）"
    fi
}

## --prefix は最終名から拡張子を外したもの（衝突で <親>_ が付いても、展開したフォルダ名と揃う）
__lfscp_fmt_create() {
    local stem
    stem="$(basename -- "$2")"
    stem="${stem%.tar.gz}"
    __lfscp_run_quiet git -C "$1" archive --format=tar.gz --prefix="${stem}/" -o "$2" HEAD
}

__lfscp_fmt_verify() {
    __lfscp_run_quiet gzip -t "$1"
}
