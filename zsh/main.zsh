#!/usr/bin/env zsh

######################################################################
#
# Main
#
######################################################################
__rayrc_delegate_main() {
    ### auto setup
    for __rayrc_package in "${__rayrc_all_packages[@]}"; do

        # echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_main_dir}/${__rayrc_package}" &&
            -f "${__rayrc_main_dir}/${__rayrc_package}/main.zsh" &&
            ! -f "${__rayrc_main_dir}/${__rayrc_package}/disable" ]]; then

            # echo source "${__rayrc_main_dir}/${__rayrc_package}/main.zsh"
            source "${__rayrc_main_dir}/${__rayrc_package}/main.zsh"
        fi

    done
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

    local __rayrc_all_packages
    local __rayrc_packages_to_install
    declare -a __rayrc_all_packages
    declare -a __rayrc_packages_to_install

    ## populate __rayrc_all_packages
    for __rayrc_package in $(ls -1 "${__rayrc_main_dir}"); do

        # echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_main_dir}/${__rayrc_package}" && -f "${__rayrc_main_dir}/${__rayrc_package}/main.zsh" ]]; then
            # echo "  .rayrc: package name to be added '${__rayrc_package}'.."
            __rayrc_all_packages+=("${__rayrc_package}")
        fi
    done
    # echo "\${__rayrc_all_packages[@]}: ${__rayrc_all_packages[@]}"
    # echo "\${#__rayrc_all_packages[@]}: ${#__rayrc_all_packages[@]}"
    # for j in {1..${#__rayrc_all_packages[@]}..1}; do
    #     echo "\${__rayrc_all_packages[$j]}: ${__rayrc_all_packages[$j]}"
    # done

    source "${__rayrc_main_dir}/common.zsh"
    unset -f __rayrc_filter_packages
    unset -f __rayrc_enable_packages
    unset -f __rayrc_disable_packages
    unset -f __rayrc_populate_arrays
    unset -f __rayrc_print_help
    # echo "\${__rayrc_packages_to_install[@]}: ${__rayrc_packages_to_install[@]}"
    # echo "\${#__rayrc_packages_to_install[@]}: ${#__rayrc_packages_to_install[@]}"
    # for j in {1..${#__rayrc_packages_to_install[@]}..1}; do
    #     echo "\${__rayrc_packages_to_install[$j]}: ${__rayrc_packages_to_install[$j]}"
    # done

    ## __rayrc_facts
    local __rayrc_facts_os_type
    __rayrc_determine_os_type
    unset -f __rayrc_determine_os_type
    # echo "\${__rayrc_facts_os_type}: ${__rayrc_facts_os_type}"

    local __rayrc_facts_os_distribution
    local __rayrc_package_manager
    __rayrc_determin_os_distribution
    unset -f __rayrc_determin_os_distribution
    # echo "\${__rayrc_facts_os_distribution}: ${__rayrc_facts_os_distribution}"
    # echo "\${__rayrc_package_manager}: ${__rayrc_package_manager}"

    __rayrc_delegate_main
}

__rayrc_delegate_entry "${0:A:h}" "$@"

unset -f __rayrc_module_common_setup
unset -f __rayrc_delegate_main
unset -f __rayrc_delegate_entry
