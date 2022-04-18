#!/usr/bin/env bash


__rayrc_install_bin() {
    local __rayrc_dir_ctl_bin
    #
    # defined in ROOT/bash/install.sh as it is global.
    # local __rayrc_dir_data_bin


    __rayrc_dir_ctl_bin="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_bin}: ${__rayrc_dir_ctl_bin}"

    __rayrc_dir_data_bin="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_bin}: ${__rayrc_dir_data_bin}"


    [[ ! -d "${__rayrc_dir_data_bin}" ]] && mkdir -p "${__rayrc_dir_data_bin}"
}

__rayrc_install_bin
unset -f __rayrc_install_bin


