#!/bin/bash
#
# bash/ 配下のモジュールを移動し、対応する libs/ 側（data plane）も合わせて移動する。
#
#   mv_util.sh --from 04_text/10_bat --to 06_filesearch/10_bat
#     bash/04_text/10_bat → bash/06_filesearch/10_bat
#     libs/text/bat       → libs/filesearch/bat
#
# - libs/ 側のパスは __rayrc_package:3 と同じく、各階層の番号プレフィックス（先頭 3 文字）を外して求める
# - 移動先の親グループがなければ作成し、delegate 用の install.sh / main.sh を置く
# - 追跡ファイルを含むディレクトリは git mv（ignore された実行時データもディレクトリごと移る）、
#   追跡ファイルがなければ mv で移動する
#


#######################################################################
#
# Init
#
#######################################################################
init_globals() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

    ## __rayrc_libs_dir と同じく物理パスにそろえる（シンボリックリンクの比較に使う）
    ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
    cd "${ROOT_DIR}" || exit 1

    CTL_ROOT="bash"
    DATA_ROOT="libs"

    FROM_CTL="${CTL_ROOT}/${from}"
    TO_CTL="${CTL_ROOT}/${to}"
    FROM_DATA="${DATA_ROOT}/$(to_data_path "${from}")"
    TO_DATA="${DATA_ROOT}/$(to_data_path "${to}")"
}


#######################################################################
#
# Main
#
#######################################################################
main() {
    init_globals
    validate_paths

    log_info "control plane: ${FROM_CTL} -> ${TO_CTL}"
    log_info "data plane   : ${FROM_DATA} -> ${TO_DATA}"

    ensure_group_dirs || die "グループの作成に失敗しました。"
    move_control_plane || die "control plane の移動に失敗しました。"
    move_data_plane || die "data plane の移動に失敗しました。control plane は移動済みなので、git status で状態を確認してください。"

    warn_empty_groups
    warn_broken_symlinks
    warn_stale_references

    log_info "完了しました。git status で変更内容を確認してください。"
}


validate_paths() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        die "${ROOT_DIR} は git リポジトリではありません。"
    fi

    if [[ ! -d "${FROM_CTL}" ]]; then
        die "移動元のモジュールが見つかりません: ${FROM_CTL}"
    fi

    if [[ -e "${TO_CTL}" ]]; then
        die "移動先がすでに存在します: ${TO_CTL}"
    fi

    ## 同じグループ内の番号変更（48_lf → 38_lf）では data plane のパスが変わらない
    if [[ "${FROM_DATA}" != "${TO_DATA}" && -e "${TO_DATA}" ]]; then
        die "data plane の移動先がすでに存在します: ${TO_DATA}"
    fi

    validate_parent_groups
    validate_nested_data
}


## 既存の親ディレクトリが delegate を持たない（末端のモジュールなど）と、移したモジュールが読み込まれない
validate_parent_groups() {
    local dir phase
    for dir in $(ancestor_dirs "${to}"); do
        [[ -d "${CTL_ROOT}/${dir}" ]] || continue

        for phase in install main; do
            if [[ -f "${FROM_CTL}/${phase}.sh" ]] &&
               ! grep -q '__rayrc_source_facade' "${CTL_ROOT}/${dir}/${phase}.sh" 2>/dev/null; then
                die "${CTL_ROOT}/${dir}/${phase}.sh が delegate ではないため、${phase}.sh が読み込まれなくなります。"
            fi
        done
    done
}


## libs/bash → libs/bash/common のように自分自身の配下へ移すとき、
## 移動元にはグループ内の他モジュールの data が入っていてはいけない（一緒に移ってしまう）
validate_nested_data() {
    is_ancestor "${FROM_DATA}" "${TO_DATA}" || return 0

    ## FROM_DATA に対応する bash 側のグループを探す（例: libs/bash ↔ bash/08_bash）
    local group=""
    local dir
    for dir in $(ancestor_dirs "${to}"); do
        if [[ "${DATA_ROOT}/$(to_data_path "${dir}")" == "${FROM_DATA}" ]]; then
            group="${dir}"
        fi
    done
    [[ -n "${group}" && -d "${CTL_ROOT}/${group}" ]] || return 0

    local child name
    for child in "${CTL_ROOT}/${group}"/[0-9][0-9]_*/; do
        [[ -d "${child}" ]] || continue
        name="${child%/}"
        name="${name##*/}"
        if [[ -e "${FROM_DATA}/${name:3}" ]]; then
            die "${FROM_DATA}/${name:3} は ${CTL_ROOT}/${group}/${name} の data です。${from} を先に移動してください。"
        fi
    done
}


ensure_group_dirs() {
    local dir
    for dir in $(ancestor_dirs "${to}"); do
        if [[ ! -d "${CTL_ROOT}/${dir}" ]]; then
            create_group "${CTL_ROOT}/${dir}" || return 1
        fi
    done
}


create_group() {
    local dir="$1"
    local phase

    mkdir -p "${dir}" || return 1
    for phase in install main; do
        write_delegate "${phase}" >"${dir}/${phase}.sh" || return 1
    done
    git add "${dir}/install.sh" "${dir}/main.sh" || return 1

    log_info "グループを作成しました: ${dir}（delegate: install.sh, main.sh）"
}


move_control_plane() {
    move_path "${FROM_CTL}" "${TO_CTL}"
}


move_data_plane() {
    if [[ ! -e "${FROM_DATA}" ]]; then
        log_info "data plane はないのでスキップします: ${FROM_DATA}"
        return 0
    fi

    if [[ "${FROM_DATA}" == "${TO_DATA}" ]]; then
        log_info "data plane のパスは変わらないのでスキップします: ${FROM_DATA}"
        return 0
    fi

    if is_ancestor "${FROM_DATA}" "${TO_DATA}"; then
        ## 自分自身の配下へは直接移せないので、一時的な名前を経由する
        local tmp="${FROM_DATA}.mv_util.$$"
        if [[ -e "${tmp}" ]]; then
            log_error "一時ディレクトリがすでに存在します: ${tmp}"
            return 1
        fi
        move_path "${FROM_DATA}" "${tmp}" || return 1
        move_path "${tmp}" "${TO_DATA}" || return 1
    else
        move_path "${FROM_DATA}" "${TO_DATA}" || return 1
    fi
}


warn_empty_groups() {
    if [[ "${from}" == */* ]]; then
        local group="${CTL_ROOT}/${from%/*}"
        if ! compgen -G "${group}/[0-9][0-9]_*/" >/dev/null; then
            log_warn "${group} にはサブモジュールがなくなりました（delegate だけが残っています）。不要なら git rm -r で削除してください。"
        fi
    fi

    local data_parent="${FROM_DATA%/*}"
    if [[ "${data_parent}" != "${DATA_ROOT}" && -d "${data_parent}" && -z "$(ls -A "${data_parent}")" ]]; then
        log_warn "${data_parent} が空になりました。不要なら削除してください。"
    fi
}


## $HOME 直下で、移動前の data plane を指しているシンボリックリンク（例: ~/.vim）を知らせる
warn_broken_symlinks() {
    local old_path="${ROOT_DIR}/${FROM_DATA}"
    local new_path="${ROOT_DIR}/${TO_DATA}"
    local link target

    for link in "${HOME}"/.[!.]* "${HOME}"/*; do
        [[ -L "${link}" ]] || continue
        target="$(readlink "${link}")"
        if [[ "${target}" == "${old_path}" || "${target}" == "${old_path}/"* ]]; then
            log_warn "シンボリックリンクが切れました: ${link} -> ${target}"
            log_warn "  新しいリンク先: ${new_path}${target#"${old_path}"}（install を再実行するか、ln -snf で張り直してください）"
        fi
    done
}


## 移動前のパスを直接書いている箇所を知らせる（docs/ は経緯の記録なので除く）
## powershell/ は libs\viewer\yazi\config のように \ 区切りで data plane を参照している
warn_stale_references() {
    local hits
    hits="$(git grep -n -I -F -e "${from}" -e "${FROM_DATA}" -e "${FROM_DATA//\//\\}" -- . ':!docs/' 2>/dev/null)"
    if [[ -n "${hits}" ]]; then
        log_warn "移動前のパス（${from} / ${FROM_DATA}）を参照している箇所があります:"
        echo "${hits}" | sed 's/^/        /' >&2
    fi
}


#######################################################################
#
# Helper
#
#######################################################################
log_info() {
    echo "[INFO]  $*"
}


log_warn() {
    echo "[WARN]  $*" >&2
}


log_error() {
    echo "[ERROR] $*" >&2
}


die() {
    log_error "$*"
    exit 1
}


print_usage() {
    echo "Usage: ${0##*/} --from <module> --to <module>"
    echo "       <module> は bash/ からの相対パス（例: --from 04_text/10_bat --to 06_filesearch/10_bat）"
}


## グループ用の delegate（既存グループ、例えば bash/04_text/{install,main}.sh と同じ内容）
write_delegate() {
    local phase="$1"

    cat <<EOF
#!/usr/bin/env bash

__rayrc_${phase}() {
    __rayrc_module_common_setup
    __rayrc_source_facade ${phase}
}

__rayrc_${phase}
unset -f __rayrc_${phase}
EOF
}


## 04_text/10_bat → text/bat（__rayrc_package:3 と同じく、各階層の先頭 3 文字を外す）
to_data_path() {
    local parts part
    local result=""

    IFS='/' read -ra parts <<<"$1"
    for part in "${parts[@]}"; do
        result="${result:+${result}/}${part:3}"
    done
    echo "${result}"
}


## 02_net/sub/10_eget → "02_net 02_net/sub"（自分自身は含めない、浅い順）
ancestor_dirs() {
    local path="$1"
    local parts
    local dir=""
    local i

    IFS='/' read -ra parts <<<"${path}"
    for ((i = 0; i < ${#parts[@]} - 1; i++)); do
        dir="${dir:+${dir}/}${parts[$i]}"
        echo "${dir}"
    done
}


## $1 が $2 の祖先ディレクトリなら 0
is_ancestor() {
    [[ "$2" == "$1/"* ]]
}


## 追跡ファイルがあれば git mv、なければ mv（git mv は追跡ファイルのないディレクトリを移せない）
move_path() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "${dst}")" || return 1

    if [[ -n "$(git ls-files -- "${src}" | head -n 1)" ]]; then
        git mv "${src}" "${dst}" || return 1
    else
        mv "${src}" "${dst}" || return 1
    fi
}


parse_arguments() {
    optspec="h-:"
    while getopts "${optspec}" opt; do
        case "${opt}" in
        -)
            case "${OPTARG}" in
            from)
                from="${!OPTIND}"
                OPTIND=$((OPTIND + 1))
                ;;
            to)
                to="${!OPTIND}"
                OPTIND=$((OPTIND + 1))
                ;;
            help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option --${OPTARG}" >&2
                print_usage >&2
                exit 1
                ;;
            esac
            ;;
        h)
            print_usage
            exit 0
            ;;
        *)
            print_usage >&2
            exit 1
            ;;
        esac
    done
}


validate_arguments() {
    if [[ -z "${from}" || -z "${to}" ]]; then
        echo "Error: --from と --to を指定する必要があります." >&2
        print_usage >&2
        exit 1
    fi

    ## 補完で付きがちな先頭の bash/ と末尾の / は外す
    from="${from#bash/}"
    from="${from%/}"
    to="${to#bash/}"
    to="${to%/}"

    local path
    for path in "${from}" "${to}"; do
        if [[ ! "${path}" =~ ^([0-9]{2}_[A-Za-z0-9._-]+/)*[0-9]{2}_[A-Za-z0-9._-]+$ ]]; then
            echo "Error: 各階層が 'NN_name' 形式の、bash/ からの相対パスを指定してください: ${path}" >&2
            exit 1
        fi
    done

    if [[ "${from}" == "${to}" ]]; then
        echo "Error: --from と --to が同じです: ${from}" >&2
        exit 1
    fi

    if is_ancestor "${from}" "${to}"; then
        echo "Error: --to を --from の配下にはできません: ${from} -> ${to}" >&2
        exit 1
    fi
}

parse_arguments "$@"
validate_arguments

## Invoke Main
main
