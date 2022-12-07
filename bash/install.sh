#!/usr/bin/env bash

## Well, but, THAT IS NOT A REASON TO WRITE UGLY CODE!!!
## Coding is just hard work, as we all know! -> It's why I strive to make it an artifact!

######################################################################
#
# Main
#
######################################################################
__rayrc_delegate_install() {
    __rayrc_global_vars

    ### auto setup Main logic
    echo ""
    for __rayrc_package in $(ls -1 "${__rayrc_main_dir}"); do

        # echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_main_dir}/${__rayrc_package}" && -f "${__rayrc_main_dir}/${__rayrc_package}/install.sh" ]]; then
            echo "  .rayrc: setting up for ${__rayrc_package:3}.."
            source "${__rayrc_main_dir}/${__rayrc_package}/install.sh"
        fi
    done

    __rayrc_bootstrap_rc
}

__rayrc_delegate_install_test01() {
    echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
}

######################################################################
# post main
######################################################################
__rayrc_bootstrap_rc() {
    ### after all installation completed, setup the .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q '.rayrc' "$HOME/.bashrc"; then
            # we assume that sed is installed..
            sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.bashrc"
        fi

        # use here document to add two lines
        "cat" <<-EOF >>"$HOME/.bashrc"
			[[ -f "${__rayrc_main_dir}/main.sh" ]] && source "${__rayrc_main_dir}/main.sh"
		EOF

        # "cat" "$HOME/.bashrc"
        echo ""
        echo ".rayrc: all done!"
        echo ".rayrc: please logout & login to enjoy your new shell environment!"
        echo ""
    elif [[ -f "$HOME/.profile" ]]; then
        if grep -q '.rayrc' "$HOME/.profile"; then
            sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.profile"
        fi

        "cat" <<-EOF >>"$HOME/.profile"
			[[ -f "${__rayrc_main_dir}/main.sh" ]] && source "${__rayrc_main_dir}/main.sh"
		EOF

    else
        echo ""
        echo ".rayrc: both .bashrc and .profile not found.."
        echo ".rayrc: you may need to add this line to your profile file manually: "
        echo ""
        echo "[[ -f \"${__rayrc_main_dir}/main.sh\" ]] && source \"${__rayrc_main_dir}/main.sh\""
        echo ""
    fi
}

######################################################################
#
#
#
######################################################################
__rayrc_getopts() {
    true
}

unset -f __rayrc_getopts

######################################################################
#
#
#
######################################################################
__rayrc_controller() {
    true
}

unset -f __rayrc_controller

######################################################################
# we'd like to install some famous, useful tools from github to this
# workstation..
######################################################################
__rayrc_url_downloader() {
    true
}
unset -f __rayrc_url_downloader

######################################################################
# we'd like to install some famous, useful tools from github to this
# workstation..
######################################################################
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

######################################################################
# pre main
######################################################################
__rayrc_global_vars() {
    ## declare global variables here
    ##   as our goal is to do all the things on the fly, I'll try to EXPORT nothing in the implementation
    local __rayrc_package_manager
    local __rayrc_bin_dir

    local __rayrc_main_dir
    __rayrc_main_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_main_dir}: ${__rayrc_main_dir}"

    local __rayrc_root_dir
    __rayrc_root_dir="$(cd -- "${__rayrc_main_dir}/.." && pwd -P)"
    local __rayrc_libs_dir
    __rayrc_libs_dir="${__rayrc_root_dir}/libs"

    local __rayrc_all_packages
    local __rayrc_installed_packages
    declare -a __rayrc_all_packages
    declare -a __rayrc_installed_packages

    for __rayrc_package in $(ls -1 "${__rayrc_main_dir}"); do

        # echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_main_dir}/${__rayrc_package}" && -f "${__rayrc_main_dir}/${__rayrc_package}/install.sh" ]]; then
            echo "  .rayrc: package name to be added '${__rayrc_package:3}'.."
            __rayrc_all_packages+=("${__rayrc_package:3}")
        fi
    done

    ## for every package
    local __rayrc_ctl_dir
    local __rayrc_data_dir
    source "${__rayrc_main_dir}/module_common_setup.sh"

    local __rayrc_facts_os_type
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        __rayrc_facts_os_type="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        __rayrc_facts_os_type="macos"
    else
        echo ""
        echo ".rayrc: not supported OS type for now.."
        echo ""
        return 8
    fi

    ## __rayrc_facts
    local __rayrc_facts_os_distribution
    #
    # would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
    #
    # for EC2:
    #   `sudo dmidecode --string system-uuid'
    #   `cat /sys/hypervisor/uuid'
    # TODO: case switch
    #       set __rayrc_facts_os_distribution
    #
    # or, create a function __rayrc_determin_os_distribution()
    #

    local __rayrc_package

    __rayrc_validate_prm "$@"
}

__rayrc_validate_prm() {
    echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
    for prm in "$@"; do
        echo "prm: $prm"
    done
}

__rayrc_global_vars "$@"
__rayrc_delegate_install_test01
# __rayrc_delegate_install

unset -f __rayrc_delegate_install
unset -f __rayrc_module_common_setup
