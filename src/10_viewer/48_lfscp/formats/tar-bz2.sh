#!/usr/bin/env bash
######################################################################
## tar-bz2（tj。tar の -j）：ディスク上の現物を tar.bz2 にする
##   名前 <base>.tar.bz2   検証 bzip2 -t
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

__lfscp_fmt_requires() {
    echo tar bzip2
}

__lfscp_fmt_resolve() {
    __lfscp_path_resolve "$1"
}

__lfscp_fmt_name() {
    printf '%s\t%s\n' "$(basename -- "$1")" ".tar.bz2"
}

__lfscp_fmt_create() {
    __lfscp_tar_create -j "$1" "$2"
}

__lfscp_fmt_verify() {
    __lfscp_run_quiet bzip2 -t "$1"
}
