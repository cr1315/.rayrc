#!/usr/bin/env bash

## THERE IS NO REASON TO WRITE UGLY CODE!!!
## Yes, coding is hard, as we all know! -> It's why we call good code an artifact!

######################################################################
#
# Main
#
######################################################################
__rayrc_delegate_install() {
    ### auto setup
    echo ""
    for __rayrc_package in "${__rayrc_packages_to_install[@]}"; do

        # echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_main_dir}/${__rayrc_package}" &&
            -f "${__rayrc_main_dir}/${__rayrc_package}/install.sh" &&
            ! -f "${__rayrc_main_dir}/${__rayrc_package}/disabled" ]]; then

            echo "  .rayrc: setting up for ${__rayrc_package:3}.."
            source "${__rayrc_main_dir}/${__rayrc_package}/install.sh" >&/dev/null
        fi
    done

    __rayrc_bootstrap_rc
}

######################################################################
# post main
######################################################################
__rayrc_bootstrap_rc() {
    ### after all installation completed, setup the .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "${__rayrc_installed_name}" "$HOME/.bashrc"; then
            # TODO: we assume that sed is installed..
            sed -i -e '/'"${__rayrc_installed_name}"'.*main\.sh/ d' "$HOME/.bashrc"
        fi

    fi

    # use here document to add two lines
    "cat" <<-EOF >>"$HOME/.bashrc"
		[[ -f "${__rayrc_main_dir}/main.sh" ]] && source "${__rayrc_main_dir}/main.sh"
	EOF

    # "cat" "$HOME/.bashrc"
    echo ""
    echo ".rayrc: all done!"
    echo ".rayrc: please logout & login again to enjoy your new shell environment!"
    echo ""
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
    local __rayrc_libs_dir
    ## maybe someone will install .rayrc to / ???
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

    source "${__rayrc_main_dir}/common.sh"
    ## populate __rayrc_all_packages
    for __rayrc_package in $(ls -1 "${__rayrc_main_dir}"); do

        # echo "\${__rayrc_main_dir}/\${__rayrc_package}: ${__rayrc_main_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_main_dir}/${__rayrc_package}" && -f "${__rayrc_main_dir}/${__rayrc_package}/install.sh" ]]; then
            # echo "  .rayrc: package name to be added '${__rayrc_package}'.."
            __rayrc_all_packages+=("${__rayrc_package}")
        fi
    done
    # echo "\${__rayrc_all_packages[@]}: ${__rayrc_all_packages[@]}"
    # echo "\${#__rayrc_all_packages[@]}: ${#__rayrc_all_packages[@]}"
    # for ((j = 0; j < "${#__rayrc_all_packages[@]}"; j++)); do
    #     echo "\${__rayrc_all_packages[$j]}: ${__rayrc_all_packages[$j]}"
    # done

    __rayrc_populate_arrays
    unset -f __rayrc_filter_packages
    unset -f __rayrc_enable_packages
    unset -f __rayrc_disable_packages
    unset -f __rayrc_populate_arrays
    unset -f __rayrc_print_help
    # echo "\${__rayrc_packages_to_install[@]}: ${__rayrc_packages_to_install[@]}"
    # echo "\${#__rayrc_packages_to_install[@]}: ${#__rayrc_packages_to_install[@]}"
    # for ((j = 0; j < "${#__rayrc_packages_to_install[@]}"; j++)); do
    #     echo "\${__rayrc_packages_to_install[$j]}: ${__rayrc_packages_to_install[$j]}"
    # done

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

__rayrc_delegate_entry "$@"

unset -f __rayrc_module_common_setup
unset -f __rayrc_bootstrap_rc
unset -f __rayrc_delegate_install
unset -f __rayrc_delegate_entry
