#!/usr/bin/env bash

__rayrc_install_bin() {
    local __rayrc_dir_ctl_bin
    #
    # defined in ROOT/bash/install.sh as it is global.
    # local __rayrc_dir_data_bin

    __rayrc_dir_ctl_bin="$1"
    # echo "\${__rayrc_dir_ctl_bin}: ${__rayrc_dir_ctl_bin}"

    __rayrc_dir_data_bin="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_bin}: ${__rayrc_dir_data_bin}"

    [[ ! -d "${__rayrc_dir_data_bin}" ]] && mkdir -p "${__rayrc_dir_data_bin}"
}

__rayrc_install_bin ${0:A:h}
unset -f __rayrc_install_bin
