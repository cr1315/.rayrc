#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -x "${__rayrc_bin_dir}/eget" ]]; then
        return 0
    fi

    ## bootstrap eget using its official installer
    (cd "${__rayrc_data_dir}" && curl -sfL https://zyedidia.github.io/eget.sh | sh) || {
        echo "  .rayrc: failed to bootstrap eget"
        return 8
    }

    cp -f "${__rayrc_data_dir}/eget" "${__rayrc_bin_dir}"
    chmod +x "${__rayrc_bin_dir}/eget"
    rm -rf "${__rayrc_data_dir}/eget"*
}

__rayrc_install
unset -f __rayrc_install
