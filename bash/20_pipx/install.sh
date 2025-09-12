#!/usr/bin/env bash

command -v python3 >&/dev/null || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    local pipx_bin

    if ! command -v pipx >&/dev/null; then
        if python3 -m venv -h >&/dev/null; then

            python3 -m venv "${__rayrc_data_dir}/self"
            (
                source "${__rayrc_data_dir}/self/bin/activate" \
                && pip install --upgrade pip \
                && pip install pipx
            ) >&/dev/null

            ln -snf "${__rayrc_data_dir}/self/bin/pipx" "${__rayrc_bin_dir}/pipx"

            export PIPX_HOME="${__rayrc_data_dir}/run"
            export PIPX_BIN_DIR="${__rayrc_bin_dir}"

            pipx_bin="${__rayrc_bin_dir}/pipx"
        fi
    else
        export PIPX_HOME="${__rayrc_data_dir}/run"
        export PIPX_BIN_DIR="${__rayrc_bin_dir}"

        pipx_bin="$(command -v pipx)"
    fi


    if ! command -v poetry >&/dev/null; then
        "${pipx_bin}" install poetry
    fi

    if ! command -v glances >&/dev/null; then
        if [[ "$__rayrc_package_manager" == "apk" ]]; then
            apk add --no-cache --virtual .build-deps build-base python3-dev libffi-dev \
                && "${pipx_bin}" install glances \
                && apk del .build-deps
        else
            "${pipx_bin}" install glances
        fi
    fi

    if ! command -v ansible >&/dev/null; then
        "${pipx_bin}" install --include-deps --system-site-packages --python python3 "ansible<2.10"
    fi
}

__rayrc_install
unset -f __rayrc_install
