#!/usr/bin/env bash

[[ -x "${__rayrc_bin_dir}/uv" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    export PIPX_HOME="${__rayrc_data_dir}/run"
    export PIPX_BIN_DIR="${__rayrc_bin_dir}"

    ## install pipx itself via uv tool (no hand-rolled venv)
    if [[ ! -x "${__rayrc_bin_dir}/pipx" ]]; then
        "${__rayrc_bin_dir}/uv" tool install --python 3.13 pipx >&/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
