#!/usr/bin/env bash
#
# control plane のロード順を静的に列挙する（実行はしない）。
#
#   load_order.sh --root <dir> --ext <sh|zsh|ps1> --phase <install|main>
#
# 出力: <root> からの相対パス（<module>/<phase>.<ext>）を実行順に 1 行ずつ。
# 並びは ordinal（LC_ALL=C / バイト順）。
#
# 意味論（全方言で共通の明示 delegate）:
#   ディレクトリに <phase>.<ext> があり、disabled が無ければ列挙する。
#   その <phase>.<ext> が facade を呼んでいる（delegate である）場合のみ、中へ再帰する。
#     sh / zsh: __rayrc_source_facade
#     ps1     : __rayrc_list_modules
#
# ランタイムのガード（70_niri/install.sh の Wayland 判定など）や --filter は評価しない。
#

set -u
export LC_ALL=C

die() {
    echo "load_order.sh: $*" >&2
    exit 1
}

## <dir> の子ディレクトリ名を ordinal 順に出す
list_child_dirs() {
    local dir="$1" entry
    for entry in "${dir}"/*; do
        if [[ -d "${entry}" ]]; then
            printf '%s\n' "${entry##*/}"
        fi
    done | sort
}

walk_delegate() {
    local dir="$1" rel="$2" name script
    while IFS= read -r name; do
        [[ -f "${dir}/${name}/${script_name}" && ! -e "${dir}/${name}/disabled" ]] || continue
        script="${dir}/${name}/${script_name}"
        printf '%s\n' "${rel}${name}/${script_name}"
        if grep -q "${facade_marker}" "${script}"; then
            walk_delegate "${dir}/${name}" "${rel}${name}/"
        fi
    done < <(list_child_dirs "${dir}")
}

main() {
    local root="" ext="" phase=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root) root="${2:-}"; shift 2 ;;
            --ext) ext="${2:-}"; shift 2 ;;
            --phase) phase="${2:-}"; shift 2 ;;
            *) die "unknown argument: $1" ;;
        esac
    done
    [[ -n "${root}" && -n "${ext}" && -n "${phase}" ]] \
        || die "usage: load_order.sh --root <dir> --ext <sh|zsh|ps1> --phase <install|main>"
    [[ -d "${root}" ]] || die "not a directory: ${root}"
    root="${root%/}"

    script_name="${phase}.${ext}"
    case "${ext}" in
        sh | zsh) facade_marker='__rayrc_source_facade' ;;
        ps1) facade_marker='__rayrc_list_modules' ;;
        *) die "unsupported ext: ${ext}" ;;
    esac
    walk_delegate "${root}" ""
}

main "$@"
