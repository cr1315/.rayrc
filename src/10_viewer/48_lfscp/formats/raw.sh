#!/usr/bin/env bash
######################################################################
## raw（tt）：ファイルそのもの（容器なし）
##   元   通常ファイルだけ。フォルダは理由を出して飛ばす（tg などで包む）
##   名前 元の名前のまま（先頭の . も残す）。衝突したときの _2 は拡張子の前に入れる
##   作成 cp -pL（シンボリックリンクは実体をコピーする）   検証 cmp
## 形式ハンドラーの契約は lfscp の pack を参照
######################################################################

__lfscp_fmt_requires() {
    echo cp cmp
}

__lfscp_fmt_resolve() {
    if [[ -d "$1" ]]; then
        echo "フォルダは tt で取れない（tg などで包む）" >&2
        return 1
    fi
    if [[ ! -f "$1" ]]; then
        echo "通常ファイルではない（または存在しない）" >&2
        return 1
    fi
    __lfscp_abs_path "$1"
}

## a.txt → a + .txt、.env → .env + なし、.config.json → .config + .json
__lfscp_fmt_name() {
    local base lead rest
    base="$(basename -- "$1")"
    lead="${base%%[!.]*}"
    rest="${base#"$lead"}"
    if [[ "$rest" == *.* ]]; then
        printf '%s\t%s\n' "${lead}${rest%.*}" ".${rest##*.}"
    else
        printf '%s\t%s\n' "$base" ""
    fi
}

__lfscp_fmt_create() {
    __lfscp_run_quiet cp -pL -- "$1" "$2"
}

__lfscp_fmt_verify() {
    __lfscp_run_quiet cmp -- "$2" "$1"
}
