#!/usr/bin/env zsh

######################################################################
#
# Main
#
######################################################################
__rayrc_delegate_install() {
    echo ""
    __rayrc_source_facade install
    __rayrc_bootstrap_rc
}

######################################################################
# post main
######################################################################
__rayrc_bootstrap_rc() {
    ### after all installation completed, setup the .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q '.rayrc' "$HOME/.zshrc"; then
            # we assume sed installed..
            sed -i -e '/\.rayrc.*main\.zsh/ d' "$HOME/.zshrc"
        fi

        # use here document to add two lines
        "cat" <<-EOF >>$HOME/.zshrc
			[[ -f "${__rayrc_main_dir}/main.zsh" ]] && source "${__rayrc_main_dir}/main.zsh"
		EOF

        # "cat" $HOME/.zshrc
        echo ""
        __rayrc_log_info "all done!"
        __rayrc_log_info "please logout & login to enjoy your new shell environment!"
    fi
}

######################################################################
#
# Entry
#
######################################################################
## pre main
__rayrc_delegate_entry() {
    ## dir
    local __rayrc_main_dir
    __rayrc_main_dir="$1"
    # echo "\${__rayrc_main_dir}: ${__rayrc_main_dir}"
    shift

    ## parameters
    local __rayrc_prms
    __rayrc_prms=("$@")
    # echo "\${__rayrc_prms}: '${__rayrc_prms}'"
    local __rayrc_yes_no

    local __rayrc_root_dir
    __rayrc_root_dir="$(cd -- "${__rayrc_main_dir}/.." && pwd -P)"
    local __rayrc_libs_dir
    __rayrc_libs_dir="$(cd -- "${__rayrc_root_dir}/libs" && pwd -P)"

    local __rayrc_bin_dir
    __rayrc_bin_dir="${__rayrc_libs_dir}/bin"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"
    if [[ ! -d "${__rayrc_bin_dir}" ]]; then
        mkdir -p "${__rayrc_bin_dir}"
    fi

    local __rayrc_ctl_dir
    local __rayrc_data_dir

    ## for packages
    local __rayrc_package

    source "${__rayrc_main_dir}/common.zsh"

    local -a __rayrc_install_filter
    __rayrc_parse_args

    ## __rayrc_facts
    local __rayrc_facts_os_type
    local __rayrc_facts_os_distribution
    local __rayrc_package_manager
    local __rayrc_pm_update_repo

    __rayrc_determine_os_type
    unset -f __rayrc_determine_os_type

    __rayrc_determin_os_distribution
    unset -f __rayrc_determin_os_distribution
    # echo "\${__rayrc_facts_os_type}: ${__rayrc_facts_os_type}"
    # echo "\${__rayrc_facts_os_distribution}: ${__rayrc_facts_os_distribution}"
    # echo "\${__rayrc_package_manager}: ${__rayrc_package_manager}"

    __rayrc_delegate_install
}

__rayrc_delegate_entry "${0:A:h}" "$@"

unset -f __rayrc_module_common_setup
unset -f __rayrc_source_facade
unset -f __rayrc_parse_args
unset -f __rayrc_bootstrap_rc
unset -f __rayrc_delegate_install
unset -f __rayrc_delegate_entry
