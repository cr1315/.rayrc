#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    ## uv keeps its standalone Pythons, tool venvs and shims inside libs/ (same as install.sh)
    export UV_TOOL_DIR="${__rayrc_data_dir}/tools"
    export UV_TOOL_BIN_DIR="${__rayrc_bin_dir}"
    export UV_PYTHON_INSTALL_DIR="${__rayrc_data_dir}/python"
    ## uv-managed Pythons only: a venv on a system Python breaks when that Python is
    ## uninstalled or upgraded (the venv only points at it)
    export UV_MANAGED_PYTHON=1

    if [[ -x "${__rayrc_bin_dir}/uv" ]]; then
        return 0
    fi

    ## UV_INSTALL_DIR: flat layout in libs/bin; UV_NO_MODIFY_PATH: rayrc owns PATH
    if ! (
        set -o pipefail
        curl -LsSf https://astral.sh/uv/install.sh \
            | env UV_INSTALL_DIR="${__rayrc_bin_dir}" UV_NO_MODIFY_PATH=1 sh
    ) >&/dev/null; then
        __rayrc_log_warn "failed to install uv"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
