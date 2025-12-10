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

__rayrc_module_common_setup() {
    # echo "__rayrc_module_common_setup: \${BASH_SOURCE[0]}: ${BASH_SOURCE[0]}"

    __rayrc_ctl_dir="${__rayrc_main_dir}/${__rayrc_package}"
    # echo "__rayrc_module_common_setup: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "__rayrc_module_common_setup: \${__rayrc_data_dir}: ${__rayrc_data_dir}"
    if [[ ! -d "${__rayrc_data_dir}" ]]; then
        mkdir -p "${__rayrc_data_dir}"
    fi
}

######################################################################
#
# parameters
#
######################################################################
__rayrc_populate_arrays() {
    local i
    local j

    local __rayrc_install_filters
    declare -a __rayrc_install_filters
    local __rayrc_enable_filters
    declare -a __rayrc_enable_filters
    local __rayrc_disable_filters
    declare -a __rayrc_disable_filters

    for ((i = 0; i < "${#__rayrc_prms[@]}"; i++)); do
        # echo "__rayrc_prms[$i]: ${__rayrc_prms[$i]}"
        case "${__rayrc_prms[$i]}" in
        --install)
            i=$((i + 1))
            __rayrc_install_filters=(${__rayrc_prms[$i]//,/ })
            # echo "\${__rayrc_install_filters[@]}: ${__rayrc_install_filters[@]}"
            # for ((j = 0; j < "${#__rayrc_install_filters[@]}"; j++)); do
            #     echo "\${__rayrc_install_filters[$j]}: ${__rayrc_install_filters[$j]}"
            # done
            ;;
        --enable)
            i=$((i + 1))
            __rayrc_enable_filters=(${__rayrc_prms[$i]//,/ })
            ;;
        --disable)
            i=$((i + 1))
            __rayrc_disable_filters=(${__rayrc_prms[$i]//,/ })
            ;;
        *)
            __rayrc_print_help
            ;;
        esac
    done

    __rayrc_filter_packages
    __rayrc_enable_packages
    __rayrc_disable_packages
}

__rayrc_filter_packages() {
    local filter_matched
    # echo "\${__rayrc_install_filters[@]}: ${__rayrc_install_filters[@]}"
    # echo "\${#__rayrc_install_filters[@]}: ${#__rayrc_install_filters[@]}"
    # for ((j = 0; j < "${#__rayrc_install_filters[@]}"; j++)); do
    #     echo "\${__rayrc_install_filters[$j]}: ${__rayrc_install_filters[$j]}"
    # done
    if [[ "${#__rayrc_install_filters[@]}" -gt 0 ]]; then
        for ((i = 0; i < "${#__rayrc_all_packages[@]}"; i++)); do
            __rayrc_package="${__rayrc_all_packages[$i]}"
            # echo "\${__rayrc_package}: ${__rayrc_package}"
            filter_matched=false

            for ((j = 0; j < "${#__rayrc_install_filters[@]}"; j++)); do
                # echo "\${__rayrc_install_filters[$j]}: ${__rayrc_install_filters[$j]}"
                if [[ "${__rayrc_package}" == *"${__rayrc_install_filters[$j]}" ]]; then
                    filter_matched=true
                    break
                fi
            done

            if [[ "${filter_matched}" == "true" ]]; then
                __rayrc_packages_to_install+=("${__rayrc_package}")
            fi
        done
    else
        __rayrc_packages_to_install=("${__rayrc_all_packages[@]}")
    fi
}

__rayrc_enable_packages() {
    local filter_matched
    # echo "\${__rayrc_enable_filters[@]}: ${__rayrc_enable_filters[@]}"
    # echo "\${#__rayrc_enable_filters[@]}: ${#__rayrc_enable_filters[@]}"
    # for ((j = 0; j < "${#__rayrc_enable_filters[@]}"; j++)); do
    #     echo "\${__rayrc_enable_filters[$j]}: ${__rayrc_enable_filters[$j]}"
    # done
    if [[ "${#__rayrc_enable_filters[@]}" -gt 0 ]]; then
        for ((i = 0; i < "${#__rayrc_all_packages[@]}"; i++)); do
            __rayrc_package="${__rayrc_all_packages[$i]}"
            # echo "\${__rayrc_package}: ${__rayrc_package}"
            filter_matched=false

            for ((j = 0; j < "${#__rayrc_enable_filters[@]}"; j++)); do
                # echo "\${__rayrc_enable_filters[$j]}: ${__rayrc_enable_filters[$j]}"
                if [[ "${__rayrc_package}" == *"${__rayrc_enable_filters[$j]}" ]]; then
                    filter_matched=true
                    break
                fi
            done

            if [[ "${filter_matched}" == "true" && -f "${__rayrc_main_dir}/${__rayrc_package}/disabled" ]]; then
                rm -f "${__rayrc_main_dir}/${__rayrc_package}/disabled"
            fi
        done
    fi
}

__rayrc_disable_packages() {
    local filter_matched
    # echo "\${__rayrc_disable_filters[@]}: ${__rayrc_disable_filters[@]}"
    # echo "\${#__rayrc_disable_filters[@]}: ${#__rayrc_disable_filters[@]}"
    # for ((j = 0; j < "${#__rayrc_disable_filters[@]}"; j++)); do
    #     echo "\${__rayrc_disable_filters[$j]}: ${__rayrc_disable_filters[$j]}"
    # done
    if [[ "${#__rayrc_disable_filters[@]}" -gt 0 ]]; then
        for ((i = 0; i < "${#__rayrc_all_packages[@]}"; i++)); do
            __rayrc_package="${__rayrc_all_packages[$i]}"
            # echo "\${__rayrc_package}: ${__rayrc_package}"
            filter_matched=false

            for ((j = 0; j < "${#__rayrc_disable_filters[@]}"; j++)); do
                # echo "\${__rayrc_disable_filters[$j]}: ${__rayrc_disable_filters[$j]}"
                if [[ "${__rayrc_package}" == *"${__rayrc_disable_filters[$j]}" ]]; then
                    filter_matched=true
                    break
                fi
            done

            if [[ "${filter_matched}" == "true" && ! -f "${__rayrc_main_dir}/${__rayrc_package}/disabled" ]]; then
                touch "${__rayrc_main_dir}/${__rayrc_package}/disabled"
            fi
        done
    fi
}

__rayrc_print_help() {
    echo "If you don't want to bother, just run this line:"
    echo "  ~/.rayrc/install"
    echo ""
    echo "However, by default, we don't install eza (a cool tool that can replace \`ls'),"
    echo "if you want to include it, you can do like this:"
    echo "  ~/.rayrc/install --enable eza"
    echo ""
    echo "If you've already installed and is using .rayrc now, and you want to separately"
    echo "install a package, maybe eza?"
    echo "  ~/.rayrc/install --enable eza --install eza"
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
        echo ".rayrc: could not determine OS type..."
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
                echo ".rayrc: could not determine OS distribution.."
                echo ""
                return 8
            fi
        else
            echo ""
            echo ".rayrc: could not determine OS distribution.."
            echo ""
        fi
    else
        echo ""
        echo ".rayrc: not supported OS type for bash.."
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
