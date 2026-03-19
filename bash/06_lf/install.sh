#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_eget_install "gokcehan/lf" "lf" || return 8

    ## preapre for lfrc
    if [[ ! -d "${HOME}/.cache/lf" ]]; then
        mkdir -p "${HOME}/.cache/lf"
    fi
    cp -f "${__rayrc_data_dir}/config/lf/"*preview* "${__rayrc_bin_dir}"
}

__rayrc_install
unset -f __rayrc_install
