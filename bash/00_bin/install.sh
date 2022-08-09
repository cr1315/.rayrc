#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    #
    # defined in ROOT/bash/install.sh as if it is global.
    # local __rayrc_bin_dir
    #
    __rayrc_bin_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"

    if [[ ! -d "${__rayrc_bin_dir}" ]]; then
        mkdir -p "${__rayrc_bin_dir}"
    fi
}

__rayrc_install
unset -f __rayrc_install
