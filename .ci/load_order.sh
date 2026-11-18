#!/usr/bin/env bash
#
# control plane のロード順を静的に列挙する（実行はしない）。
#
#   load_order.sh --root <dir> --ext <sh|zsh|ps1> --phase <install|main>
#
# 出力: <root> からの相対パス（<module>/<phase>.<ext>）を実行順に 1 行ずつ。
# 並びは ordinal（LC_ALL=C / バイト順）。
#
# 意味論:
#   sh / zsh (明示 delegate)
#     ディレクトリに <phase>.<ext> があり、disabled が無ければ列挙する。
#     その <phase>.<ext> が __rayrc_source_facade を含む場合のみ、中へ再帰する。
#   ps1 (現行 / legacy)  … <root>/main.ps1 に __rayrc_list_modules が無い場合
#     <root> 直下 1 階層の main.ps1 のみ（disabled は見ない）。
#   ps1 (暗黙再帰 / implicit) … <root>/main.ps1 に __rayrc_list_modules がある場合
#     disabled のあるディレクトリは飛ばす。
#     <phase>.ps1 があれば列挙して、それより下へは降りない。
#     無く、名前が NN_* で NN_* のサブディレクトリを持てば再帰する。
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
        if grep -q '__rayrc_source_facade' "${script}"; then
            walk_delegate "${dir}/${name}" "${rel}${name}/"
        fi
    done < <(list_child_dirs "${dir}")
}

walk_ps1_legacy() {
    local dir="$1" name
    while IFS= read -r name; do
        if [[ -f "${dir}/${name}/main.ps1" ]]; then
            printf '%s\n' "${name}/main.ps1"
        fi
    done < <(list_child_dirs "${dir}")
}

walk_ps1_implicit() {
    local dir="$1" rel="$2" name sub has_nn_sub
    while IFS= read -r name; do
        [[ -e "${dir}/${name}/disabled" ]] && continue
        if [[ -f "${dir}/${name}/${script_name}" ]]; then
            printf '%s\n' "${rel}${name}/${script_name}"
        elif [[ "${name}" =~ ^[0-9][0-9]_ ]]; then
            has_nn_sub=false
            while IFS= read -r sub; do
                [[ "${sub}" =~ ^[0-9][0-9]_ ]] && { has_nn_sub=true; break; }
            done < <(list_child_dirs "${dir}/${name}")
            if ${has_nn_sub}; then
                walk_ps1_implicit "${dir}/${name}" "${rel}${name}/"
            fi
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
        sh | zsh)
            walk_delegate "${root}" ""
            ;;
        ps1)
            if [[ -f "${root}/main.ps1" ]] && grep -q '__rayrc_list_modules' "${root}/main.ps1"; then
                walk_ps1_implicit "${root}" ""
            else
                [[ "${phase}" == "main" ]] || die "legacy ps1 semantics only defines --phase main"
                walk_ps1_legacy "${root}"
            fi
            ;;
        *)
            die "unsupported ext: ${ext}"
            ;;
    esac
}

main "$@"
