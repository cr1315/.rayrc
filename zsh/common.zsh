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

    local disable_output
    local release_links
    local release_links_lazy_url
    local downloaded_link

    ## https://stackoverflow.com/questions/16703647/why-does-curl-return-error-23-failed-writing-body
    release_links="$(curl -sfL "https://github.com/${bin_name}/releases/latest")"

    ## github changed real links to lazy-data..
    if disable_output="$(echo "$release_links" | grep '/expanded_assets')"; then
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

__rayrc_module_common_setup() {
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

source "${__rayrc_main_dir}/logger.zsh"

######################################################################
#
# Facade
#
######################################################################
# __rayrc_source_facade <mode>
#
# mode: install | uninstall | main → sources <mode>.zsh in each module
#
# スキャンディレクトリの決定:
#   __rayrc_ctl_dir が設定済み → そのディレクトリ（モジュール内からの呼び出し）
#   未設定 → __rayrc_main_dir（トップレベルからの呼び出し）
#
__rayrc_source_facade() {
    local mode="$1"
    local script_name="${mode}.zsh"
    local scan_dir="${__rayrc_ctl_dir:-${__rayrc_main_dir}}"

    ## save caller state (zsh も dynamic scoping — 子関数は親の local を上書きできるため)
    local saved_ctl_dir="${__rayrc_ctl_dir}"
    local saved_data_dir="${__rayrc_data_dir}"
    local saved_package="${__rayrc_package}"

    ## ループ内で local を再宣言すると、zsh は既存の値を表示してしまうので先に宣言する
    local _pkg_dir
    local _pkg
    local _token
    local -a _saved_filter

    ## (N/): ディレクトリのみ・該当なしなら空。並びは名前順（bash 側の `ls -1` と同じ）
    for _pkg_dir in "${scan_dir}"/*(N/); do
        _pkg="${_pkg_dir:t}"
        if [[ -f "${_pkg_dir}/${script_name}" &&
              ! -f "${_pkg_dir}/disabled" ]]; then

            ## 毎イテレーション親の状態にリセット（兄弟モジュール間の汚染防止）
            __rayrc_ctl_dir="${saved_ctl_dir}"
            __rayrc_data_dir="${saved_data_dir}"
            __rayrc_package="${_pkg}"

            _saved_filter=("${__rayrc_install_filter[@]}")
            if [[ "${#__rayrc_install_filter[@]}" -gt 0 ]]; then
                _token="${__rayrc_install_filter[1]}"
                if [[ "${_token}" != "*" && "${_pkg}" != *"${_token}"* ]]; then
                    continue
                fi
                __rayrc_install_filter=("${(@)__rayrc_install_filter[2,-1]}")
            fi

            if [[ "${mode}" == "install" ]]; then
                __rayrc_log_info "setting up for ${_pkg:3}.."
            fi

            source "${_pkg_dir}/${script_name}"
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
    for ((i = 1; i <= ${#__rayrc_prms[@]}; i++)); do
        case "${__rayrc_prms[$i]}" in
        --filter)
            i=$((i + 1))
            __rayrc_install_filter=("${(@s:,:)__rayrc_prms[$i]}")
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
        __rayrc_log_warn "not supported OS type for zsh.."
        echo ""
    fi
}
