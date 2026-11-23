#!/usr/bin/env bash
######################################################################
## tar-gz（tg）：ディスク上の現物（ファイルでもフォルダでも）を tar.gz にする
##   名前 <base>.tar.gz   検証 gzip -t
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

__lfscp_fmt_requires() {
    echo tar gzip
}

__lfscp_fmt_resolve() {
    __lfscp_path_resolve "$1"
}

__lfscp_fmt_name() {
    printf '%s\t%s\n' "$(basename -- "$1")" ".tar.gz"
}

__lfscp_fmt_create() {
    __lfscp_tar_create -z "$1" "$2"
}

__lfscp_fmt_verify() {
    __lfscp_run_quiet gzip -t "$1"
}
