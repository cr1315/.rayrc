#!/usr/bin/env bash

__rayrc_main() {
    __rayrc_module_common_setup

    #
    # was defined in ROOT/bash/main.sh as if it is a GLOBAL variable.
    # local __rayrc_bin_dir
    __rayrc_bin_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"

    # prepend our absolute bin path to $PATH
    if [[ ! "$PATH" == *"${__rayrc_bin_dir}"* ]]; then
        export PATH="${__rayrc_bin_dir}${PATH:+:${PATH}}"
    fi
}

__rayrc_main
unset -f __rayrc_main
