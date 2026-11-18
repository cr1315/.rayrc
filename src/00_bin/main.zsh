#!/usr/bin/env bash

__rayrc_main() {
    __rayrc_module_common_setup

    # prepend our absolute bin path to $PATH
    if [[ ! "$PATH" == *"${__rayrc_bin_dir}"* ]]; then
        export PATH="${__rayrc_bin_dir}${PATH:+:${PATH}}"
    fi
}

__rayrc_main
unset -f __rayrc_main
