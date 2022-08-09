######################################################################
#
#
#
######################################################################
__rayrc_module_common_setup() {
    # echo "__rayrc_module_common_setup: \${BASH_SOURCE[0]}: ${BASH_SOURCE[0]}"

    __rayrc_ctl_dir="${__rayrc_delegate_dir}/${__rayrc_package}"
    # echo "__rayrc_module_common_setup: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "__rayrc_module_common_setup: \${__rayrc_data_dir}: ${__rayrc_data_dir}"
    if [[ ! -d "${__rayrc_data_dir}" ]]; then
        mkdir -p "${__rayrc_data_dir}"
    fi
}
