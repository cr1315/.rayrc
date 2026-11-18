#!/usr/bin/env bash

[[ -x "${__rayrc_bin_dir}/uv" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    ## ansible<2.10 requires Python < 3.11; pin 3.10 so uv fetches a compatible
    ## standalone interpreter regardless of the system Python version.
    if [[ ! -x "${__rayrc_bin_dir}/ansible" ]]; then
        "${__rayrc_bin_dir}/uv" tool install --force \
            --python 3.10 \
            "ansible<2.10" >&/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
