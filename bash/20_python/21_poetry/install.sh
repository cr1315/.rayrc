#!/usr/bin/env bash

[[ -x "${__rayrc_bin_dir}/uv" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ ! -x "${__rayrc_bin_dir}/poetry" ]]; then
        "${__rayrc_bin_dir}/uv" tool install --force --python 3.13 poetry >&/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
