#!/usr/bin/env bash
######################################################################
## zip（tz）：ディスク上の現物を zip にする（Windows で直接開ける）
##   名前 <base>.zip   検証 unzip -tq
##   zip / unzip が無い環境では python3 -m zipfile に退避する
##   zip は既存ファイルに追記し、拡張子の無い名前には .zip を足すので、作業ファイルは
##   pack が事前に消した最終名（.zip 付き）を使う
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    __lfscp_zip_tool=zip
else
    __lfscp_zip_tool=python3
fi

__lfscp_fmt_requires() {
    if [[ "$__lfscp_zip_tool" == zip ]]; then
        echo zip unzip
    else
        echo python3
    fi
}

__lfscp_fmt_resolve() {
    __lfscp_path_resolve "$1"
}

__lfscp_fmt_name() {
    printf '%s\t%s\n' "$(basename -- "$1")" ".zip"
}

## -y：シンボリックリンクはリンクのまま入れる（tar と揃える）
## python3 は -I で、カレント（元の親フォルダ）にある zipfile.py などを読まないようにする
__lfscp_fmt_create() {
    local parent base
    parent="$(dirname -- "$1")"
    base="$(basename -- "$1")"
    if [[ "$__lfscp_zip_tool" == zip ]]; then
        (cd -- "$parent" && __lfscp_run_quiet zip -r -q -y "$2" -- "$base")
    else
        (cd -- "$parent" && __lfscp_run_quiet python3 -I -m zipfile -c "$2" "$base")
    fi
}

__lfscp_fmt_verify() {
    if [[ "$__lfscp_zip_tool" == zip ]]; then
        __lfscp_run_quiet unzip -tq "$1"
    else
        __lfscp_run_quiet python3 -I -m zipfile -t "$1"
    fi
}
