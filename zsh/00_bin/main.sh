#!/usr/bin/env bash

__rayrc_main() {
    local __rayrc_ctl_dir
    #
    # was defined in ROOT/bash/install.sh as it is a GLOBAL variable.
    # local __rayrc_bin_dir

    __rayrc_ctl_dir="$1"
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_bin_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"

    # prepend our absolute bin path to $PATH
    if [[ ! "$PATH" == *"${__rayrc_bin_dir}"* ]]; then
        export PATH="${__rayrc_bin_dir}${PATH:+:${PATH}}"
    fi
}

__rayrc_main ${0:A:h}
unset -f __rayrc_main
