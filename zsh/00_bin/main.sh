#!/usr/bin/env bash

__rayrc_main_bin() {
    local __rayrc_dir_ctl_bin
    #
    # was defined in ROOT/bash/install.sh as it is a GLOBAL variable.
    # local __rayrc_dir_data_bin

    __rayrc_dir_ctl_bin="$1"
    # echo "\${__rayrc_dir_ctl_bin}: ${__rayrc_dir_ctl_bin}"

    __rayrc_dir_data_bin="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_bin}: ${__rayrc_dir_data_bin}"

    # prepend our absolute bin path to $PATH
    if [[ ! "$PATH" == *"${__rayrc_dir_data_bin}"* ]]; then
        export PATH="${__rayrc_dir_data_bin}${PATH:+:${PATH}}"
    fi
}

__rayrc_main_bin ${0:A:h}
unset -f __rayrc_main_bin
