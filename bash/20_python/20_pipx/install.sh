#!/usr/bin/env bash

command -v python3 >&/dev/null || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if ! command -v pipx >&/dev/null; then
        if python3 -m venv -h >&/dev/null; then
            python3 -m venv "${__rayrc_data_dir}/self"
            (
                source "${__rayrc_data_dir}/self/bin/activate" \
                && pip install --upgrade pip \
                && pip install pipx
            ) >&/dev/null

            ln -snf "${__rayrc_data_dir}/self/bin/pipx" "${__rayrc_bin_dir}/pipx"
        fi
    fi

    export PIPX_HOME="${__rayrc_data_dir}/run"
    export PIPX_BIN_DIR="${__rayrc_bin_dir}"
}

__rayrc_install
unset -f __rayrc_install
