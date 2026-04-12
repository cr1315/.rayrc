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

## eget-based installer helper — available to all subsequent tool modules in this install session
__rayrc_eget_install() {
    local repo="$1"
    local binary_name="$2"
    shift 2

    if [[ ! -x "${__rayrc_bin_dir}/eget" ]]; then
        __rayrc_log_warn "eget not found, cannot install ${repo}"
        return 8
    fi

    "${__rayrc_bin_dir}/eget" "${repo}" --to "${__rayrc_bin_dir}/${binary_name}" "$@" || {
        __rayrc_log_warn "failed to install ${binary_name} from ${repo}"
        return 8
    }
}
