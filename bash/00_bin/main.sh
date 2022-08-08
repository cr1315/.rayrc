#!/usr/bin/env bash

__rayrc_main() {
    local __rayrc_ctl_dir
    __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    #
    # was defined in ROOT/bash/main.sh as if it is a GLOBAL variable.
    # local __rayrc_bin_dir
    __rayrc_bin_dir="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"

    # prepend our absolute bin path to $PATH
    if [[ ! "$PATH" == *"${__rayrc_bin_dir}"* ]]; then
        export PATH="${__rayrc_bin_dir}${PATH:+:${PATH}}"
    fi
}

__rayrc_main
unset -f __rayrc_main
