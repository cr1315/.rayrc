#!/usr/bin/env bash

command -v python3 >&/dev/null || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if ! command -v pipx >&/dev/null; then
        python3 -m venv "${__rayrc_data_dir}/self"
        (
            source "${__rayrc_data_dir}/self/bin/activate"
            pip install --upgrade pip
            pip install pipx
        ) >&/dev/null

        ln -snf "${__rayrc_data_dir}/self/bin/pipx" "${__rayrc_bin_dir}/pipx"

        export PIPX_HOME="${__rayrc_data_dir}/run"
        export PIPX_BIN_DIR="${__rayrc_bin_dir}"

        if ! command -v poetry >&/dev/null; then
            "${__rayrc_bin_dir}/pipx" install poetry
        fi

        if ! command -v glances >&/dev/null; then
            "${__rayrc_bin_dir}/pipx" install glances
        fi

        if ! command -v ansible >&/dev/null; then
            "${__rayrc_bin_dir}/pipx" install --include-deps --system-site-packages "ansible<2.10"
        fi

    else
        export PIPX_HOME="${__rayrc_data_dir}/run"
        export PIPX_BIN_DIR="${__rayrc_bin_dir}"

        if ! command -v poetry >&/dev/null; then
            pipx install poetry
        fi

        if ! command -v glances >&/dev/null; then
            pipx install glances
        fi

        if ! command -v ansible >&/dev/null; then
            pipx install --include-deps --system-site-packages "ansible<2.10"
        fi
    fi
}

__rayrc_install
unset -f __rayrc_install
