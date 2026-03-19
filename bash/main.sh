#!/usr/bin/env bash

######################################################################
#
# Main
#
######################################################################
__rayrc_delegate_main() {
    __rayrc_source_facade main
}

######################################################################
#
# Entry
#
######################################################################
## pre main
__rayrc_delegate_entry() {
    ## parameters
    local __rayrc_prms
    __rayrc_prms=("$@")
    local __rayrc_yes_no

    ## dir
    local __rayrc_main_dir
    __rayrc_main_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_main_dir}: ${__rayrc_main_dir}"

    local __rayrc_root_dir
    __rayrc_root_dir="$(cd -- "${__rayrc_main_dir}/.." && pwd -P)"
    # (cd ${__rayrc_root_dir} && git pull &>/dev/null)

    ## TODO: auto-determine "${__rayrc_parent_dir}/.rayrc_per_project/" and source its main.sh
    # local __rayrc_parent_dir
    # __rayrc_parent_dir="$(cd -- "${__rayrc_root_dir}/.." && pwd -P)"

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

    source "${__rayrc_main_dir}/common.sh"

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

    __rayrc_delegate_main
}

__rayrc_delegate_entry "$@"

unset -f __rayrc_module_common_setup
unset -f __rayrc_source_facade
unset -f __rayrc_delegate_main
unset -f __rayrc_delegate_entry
