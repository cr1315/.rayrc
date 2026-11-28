######################################################################
#
# Helper
#
######################################################################
## we'd like to install some famous, useful tools from github to this workstation..
__rayrc_github_downloader() {
    local bin_name
    local target_path

    bin_name="$1"
    target_path="$2"
    shift
    shift

    local release_links
    local release_links_lazy_url
    local downloaded_link

    ## https://stackoverflow.com/questions/16703647/why-does-curl-return-error-23-failed-writing-body
    release_links="$(curl -sfL "https://github.com/${bin_name}/releases/latest")"

    ## github changed real links to lazy-data..
    if echo "$release_links" | grep '/expanded_assets' >&/dev/null; then
        release_links_lazy_url="$(echo "$release_links" | grep '/expanded_assets' | grep -oE 'src="[^"]*' | grep -oE 'http.*')"
        release_links="$(curl -sfL "${release_links_lazy_url}")"
    fi
    if release_links="$(echo "$release_links" | grep 'href="' | grep 'download/')"; then
        # echo "release_links: ${release_links}"
        true
    else
        ## fail fast..
        echo "unable to extract download link for ${bin_name}:"
        echo "release_links: ${release_links}"
        return 8
    fi

    # while [[ `echo "$release_links" | wc -l` -gt 1 && -n "$1" ]]; do
    while [[ $(echo "$release_links" | wc -l) -gt 1 && ! "$1" =~ ^[[:space:]]*$ ]]; do
        release_links="$(echo "$release_links" | grep -E "$1")"
        shift
    done

    if [[ $(echo "$release_links" | wc -l) -ne 1 || "$release_links" =~ ^[[:space:]]*$ ]]; then
        echo "unable to extract download link for ${bin_name}:"
        echo "release_links: ${release_links}"
        return 8
    fi

    downloaded_link="$(echo "$release_links" | grep -oE 'href="[^"]+' | grep -oE '/.*')"
    # echo "https://github.com${downloaded_link}"
    curl -fsL "https://github.com${downloaded_link}" --create-dirs -o "${target_path}"
    return 0
}

## __rayrc_install_binary <file> <pattern>[=<name>] [<pattern>[=<name>]...]
##
## ダウンロードした <file> からバイナリを取り出して ${__rayrc_bin_dir}/<name> に置き、<file> は消す。
##   - <file> が .tar.gz / .tgz / .tar.xz / .tar.bz2 / .zip のとき: 一時ディレクトリに展開し、
##     ファイル名が <pattern>（find -name の glob）に一致するものを深さを問わず探す。
##     アーカイブが平らか、トップにディレクトリを持つかを気にしなくてよい
##     （GNU tar の --transform / bsdtar の --strip-components の違いもここで消える）
##   - それ以外のとき: <file> そのものがバイナリ。最初の <pattern>（または <name>）の名前で置く
##   - <name> を省くと <pattern> をそのまま名前にする（例: 'gdu_*=gdu'、'bat'）
## 置き換えは bin dir 内の一時ファイルからの mv で行う（実行中のバイナリでも ETXTBSY にならない）。
## bash / zsh の両方で同じ本文が動く（common.zsh にも同じものを置いている）。
__rayrc_install_binary() {
    local file="$1"
    shift

    local spec pattern name found work err
    local rc=0

    if [[ ! -f "${file}" ]]; then
        __rayrc_log_warn "downloaded file not found: ${file}"
        return 8
    fi

    case "${file}" in
        *.tar.gz | *.tgz | *.tar.xz | *.txz | *.tar.bz2 | *.tbz2 | *.zip)
            work="$(mktemp -d "${file}.XXXXXX")" || return 8
            case "${file}" in
                *.zip) err="$(unzip -qo "${file}" -d "${work}" 2>&1)" ;;
                *) err="$(tar xf "${file}" -C "${work}" 2>&1)" ;;
            esac
            if [[ $? -ne 0 ]]; then
                __rayrc_log_warn "failed to extract ${file##*/}: ${err}"
                rm -rf "${work}" "${file}"
                return 8
            fi

            for spec in "$@"; do
                pattern="${spec%%=*}"
                name="${spec#*=}"
                found="$(find "${work}" -type f -name "${pattern}" | head -n 1)"
                if [[ -z "${found}" ]]; then
                    __rayrc_log_warn "${pattern} not found in ${file##*/}"
                    rc=8
                    continue
                fi
                __rayrc_place_binary "${found}" "${name}" || rc=8
            done
            rm -rf "${work}"
            ;;
        *)
            spec="$1"
            __rayrc_place_binary "${file}" "${spec#*=}" || rc=8
            ;;
    esac

    rm -f "${file}"
    return "${rc}"
}

## __rayrc_place_binary <src> <name> — __rayrc_install_binary の下請け
__rayrc_place_binary() {
    local tmp="${__rayrc_bin_dir}/.${2}.rayrc_tmp"
    cp -f "$1" "${tmp}" && chmod 755 "${tmp}" && mv -f "${tmp}" "${__rayrc_bin_dir}/${2}" || {
        rm -f "${tmp}"
        __rayrc_log_warn "failed to place ${2} into ${__rayrc_bin_dir}"
        return 8
    }
}

## __rayrc_sed_inplace <file> <sed args...>
##
## `sed -i` that works the same with GNU and BSD (macOS) sed, which disagree on
## the backup-suffix argument (BSD takes `sed -i -e ...` as suffix "-e").
## Writing back through `cat >` also keeps a symlinked file (dotfile managers) intact.
__rayrc_sed_inplace() {
    local file="$1"
    shift

    local tmp
    tmp="$(mktemp)" || return 8

    if ! sed "$@" "${file}" >"${tmp}"; then
        rm -f "${tmp}"
        return 8
    fi
    cat "${tmp}" >"${file}"
    rm -f "${tmp}"
}

## __rayrc_rc_block <rc file> [<line>]
##
## rc ファイルへの登録を、install.ps1 と同じくマーカーで囲んだ managed block で管理する:
##   # >>> rayrc >>>
##   <line>
##   # <<< rayrc <<<
##
## <line> あり（登録）:
##   - managed block があれば、その場で置き換える（複数あれば最初の 1 つに畳む）
##   - 無ければ、旧形式の行（マーカー導入前の `.rayrc.../main.(sh|zsh)`）を消してから末尾に追記する
## <line> なし（削除）:
##   - managed block と旧形式の行の両方を消す
## マーカーの数が合わない（手で壊された）ときは、何も書き換えずに 8 を返す。
__rayrc_rc_block() {
    local rc="$1"
    local line="${2-}"
    local begin='# >>> rayrc >>>'
    local end='# <<< rayrc <<<'

    local n_begin n_end
    n_begin="$(grep -cxF "${begin}" "${rc}")"
    n_end="$(grep -cxF "${end}" "${rc}")"
    if [[ "${n_begin}" -ne "${n_end}" ]]; then
        __rayrc_log_warn "unbalanced rayrc markers in ${rc}, please fix it by hand"
        return 8
    fi

    if [[ "${n_begin}" -gt 0 ]]; then
        ## sed の a/c/r は GNU と BSD で書式が違うので、行単位で組み立て直す
        local tmp cur
        local in_block=false
        local replaced=false
        tmp="$(mktemp)" || return 8
        while IFS= read -r cur || [[ -n "${cur}" ]]; do
            if ${in_block}; then
                [[ "${cur}" == "${end}" ]] && in_block=false
            elif [[ "${cur}" == "${begin}" ]]; then
                in_block=true
                if ! ${replaced} && [[ -n "${line}" ]]; then
                    printf '%s\n%s\n%s\n' "${begin}" "${line}" "${end}"
                fi
                replaced=true
            else
                printf '%s\n' "${cur}"
            fi
        done <"${rc}" >"${tmp}"
        cat "${tmp}" >"${rc}"
        rm -f "${tmp}"

        [[ -n "${line}" ]] && return 0
    fi

    __rayrc_sed_inplace "${rc}" -E -e '/\.rayrc.*\/main\.(sh|zsh)/ d' || return 8
    [[ -z "${line}" ]] && return 0

    ## 末尾に改行の無いファイルへ追記しても、最終行とつながらないようにする
    if [[ -s "${rc}" && -n "$(tail -c 1 "${rc}")" ]]; then
        printf '\n' >>"${rc}"
    fi
    printf '%s\n%s\n%s\n' "${begin}" "${line}" "${end}" >>"${rc}"
}


__rayrc_module_common_setup() {
    # echo "__rayrc_module_common_setup: \${BASH_SOURCE[0]}: ${BASH_SOURCE[0]}"

    ## idempotency guard — 同一モジュールで2回呼ばれても二重に積み上がらない
    if [[ "${__rayrc_ctl_dir}" == *"/${__rayrc_package}" ]]; then
        return
    fi

    __rayrc_ctl_dir="${__rayrc_ctl_dir:-${__rayrc_main_dir}}/${__rayrc_package}"
    # echo "__rayrc_module_common_setup: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_data_dir:-${__rayrc_libs_dir}}/${__rayrc_package:3}"
    # echo "__rayrc_module_common_setup: \${__rayrc_data_dir}: ${__rayrc_data_dir}"
    if [[ ! -d "${__rayrc_data_dir}" ]]; then
        mkdir -p "${__rayrc_data_dir}"
    fi
}

source "${BASH_SOURCE[0]%/*}/logger.sh"

######################################################################
#
# Facade
#
######################################################################
# __rayrc_source_facade <mode>
#
# mode: install | uninstall | main → sources <mode>.sh in each module
#
# スキャンディレクトリの決定:
#   __rayrc_ctl_dir が設定済み → そのディレクトリ（モジュール内からの呼び出し）
#   未設定 → __rayrc_main_dir（トップレベルからの呼び出し）
#
__rayrc_source_facade() {
    local mode="$1"
    local script_name="${mode}.sh"
    local scan_dir="${__rayrc_ctl_dir:-${__rayrc_main_dir}}"

    ## save caller state (bash dynamic scoping — 子関数は親の local を上書きできるため)
    local saved_ctl_dir="${__rayrc_ctl_dir}"
    local saved_data_dir="${__rayrc_data_dir}"
    local saved_package="${__rayrc_package}"

    local _pkg
    for _pkg in $(ls -1 "${scan_dir}" 2>/dev/null); do
        if [[ -d "${scan_dir}/${_pkg}" &&
              -f "${scan_dir}/${_pkg}/${script_name}" &&
              ! -f "${scan_dir}/${_pkg}/disabled" ]]; then

            ## 毎イテレーション親の状態にリセット（兄弟モジュール間の汚染防止）
            __rayrc_ctl_dir="${saved_ctl_dir}"
            __rayrc_data_dir="${saved_data_dir}"
            __rayrc_package="${_pkg}"

            local _saved_filter=("${__rayrc_install_filter[@]}")
            if [[ "${#__rayrc_install_filter[@]}" -gt 0 ]]; then
                local _token="${__rayrc_install_filter[0]}"
                if [[ "${_token}" != "*" && "${_pkg}" != *"${_token}"* ]]; then
                    continue
                fi
                __rayrc_install_filter=("${__rayrc_install_filter[@]:1}")
            fi

            if [[ "${mode}" == "install" ]]; then
                __rayrc_log_info "setting up for ${_pkg:3}.."
            fi

            source "${scan_dir}/${_pkg}/${script_name}"
            __rayrc_install_filter=("${_saved_filter[@]}")
        fi
    done

    ## restore caller state（呼び出し元モジュールの変数を復元）
    __rayrc_ctl_dir="${saved_ctl_dir}"
    __rayrc_data_dir="${saved_data_dir}"
    __rayrc_package="${saved_package}"
}

######################################################################
#
# parameters
#
######################################################################
# Parses --filter a,b,c from __rayrc_prms and populates __rayrc_install_filter.
# __rayrc_install_filter must be declared (local) in the caller's scope.
__rayrc_parse_args() {
    local i
    for ((i = 0; i < "${#__rayrc_prms[@]}"; i++)); do
        case "${__rayrc_prms[$i]}" in
        --filter)
            i=$((i + 1))
            __rayrc_install_filter=(${__rayrc_prms[$i]//,/ })
            ;;
        esac
    done
}

######################################################################
#
# rayrc facts
#
######################################################################
__rayrc_determine_os_type() {
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "linux-musl"* ]]; then
        __rayrc_facts_os_type="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        __rayrc_facts_os_type="macos"

        ## we do need brew to be installed
        if ! command -v brew >&/dev/null; then
            $(which bash) -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        __rayrc_package_manager="brew"
        __rayrc_pm_update_repo="brew update"
    ## TODO: add logic for openWrt, etc..
    else
        echo ""
        __rayrc_log_warn "could not determine OS type..."
        echo ""
        return 8
    fi
}

__rayrc_determin_os_distribution() {
    #
    # would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
    #
    # for EC2:
    #   `sudo dmidecode --string system-uuid'
    #   `cat /sys/hypervisor/uuid'
    #
    if [[ "$__rayrc_facts_os_type" == "macos" ]]; then
        true
    elif [[ "$__rayrc_facts_os_type" == "linux" ]]; then
        if [[ -f "/etc/os-release" ]]; then
            if grep -q 'ubuntu' "/etc/os-release"; then
                __rayrc_facts_os_distribution="ubuntu"
                __rayrc_package_manager="apt"
                __rayrc_pm_update_repo="apt update -y"
            elif grep -q 'amazon_linux' "/etc/os-release"; then
                __rayrc_facts_os_distribution="amzn"
                __rayrc_package_manager="yum"
                __rayrc_pm_update_repo="yum makecache"
            elif grep -q 'rhel' "/etc/os-release"; then
                __rayrc_facts_os_distribution="rhel"
                __rayrc_package_manager="yum"
                __rayrc_pm_update_repo="yum makecache"
            elif grep -q 'debian' "/etc/os-release"; then
                __rayrc_facts_os_distribution="debian"
                __rayrc_package_manager="apt"
                __rayrc_pm_update_repo="apt update -y"
            elif grep -q 'centos' "/etc/os-release"; then
                __rayrc_facts_os_distribution="centos"
                __rayrc_package_manager="dnf"
                __rayrc_pm_update_repo="dnf makecache"
            elif grep -q 'photon' "/etc/os-release"; then
                __rayrc_facts_os_distribution="photon"
                __rayrc_package_manager="sudo tdnf"
                __rayrc_pm_update_repo="sudo tdnf makecache"
            elif grep -qiE 'arch' "/etc/os-release"; then
                __rayrc_facts_os_distribution="arch"
                __rayrc_package_manager="pacman"
                __rayrc_pm_update_repo="pacman -Sy"
            elif grep -qiE 'synology' "/etc/os-release"; then
                __rayrc_facts_os_type="linux"
                __rayrc_facts_os_distribution="Synology"
                ## TODO: Synology package manager
                __rayrc_package_manager="echo"
                __rayrc_pm_update_repo="echo"
            elif grep -qiE 'alpine' "/etc/os-release"; then
                __rayrc_facts_os_type="linux"
                __rayrc_facts_os_distribution="alpine"
                __rayrc_package_manager="apk"
                __rayrc_pm_update_repo="apk update"
            elif grep -qiE 'openwrt|lede' "/etc/os-release"; then
                __rayrc_facts_os_type="linux"
                __rayrc_facts_os_distribution="openwrt"
                __rayrc_package_manager="opkg"
                __rayrc_pm_update_repo="opkg update -y"
            else
                echo ""
                __rayrc_log_warn "could not determine OS distribution.."
                echo ""
                return 8
            fi
        else
            echo ""
            __rayrc_log_warn "could not determine OS distribution.."
            echo ""
        fi
    else
        echo ""
        __rayrc_log_warn "not supported OS type for bash.."
        echo ""
    fi
}

######################################################################
#
# Tests
#
######################################################################
__rayrc_delegate_entry_test01() {
    __rayrc_global_vars "$@"
    echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
}
# __rayrc_delegate_entry_test01
unset -f __rayrc_delegate_entry_test01
