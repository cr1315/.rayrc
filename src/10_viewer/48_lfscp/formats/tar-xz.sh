#!/usr/bin/env bash
######################################################################
## tar-xz（tx。tar の -J。大文字は Shift になるので x）：ディスク上の現物を tar.xz にする
##   名前 <base>.tar.xz   検証 xz -t
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

__lfscp_fmt_requires() {
    echo tar xz
}

__lfscp_fmt_resolve() {
    __lfscp_path_resolve "$1"
}

__lfscp_fmt_name() {
    printf '%s\t%s\n' "$(basename -- "$1")" ".tar.xz"
}

__lfscp_fmt_create() {
    __lfscp_tar_create -J "$1" "$2"
}

__lfscp_fmt_verify() {
    __lfscp_run_quiet xz -t "$1"
}
