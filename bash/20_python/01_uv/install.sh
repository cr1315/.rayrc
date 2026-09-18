#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## uv manages its own standalone Pythons, tool venvs and shims entirely
    ## inside libs/ — no system python3 required.
    export UV_TOOL_DIR="${__rayrc_data_dir}/tools"
    export UV_TOOL_BIN_DIR="${__rayrc_bin_dir}"
    export UV_PYTHON_INSTALL_DIR="${__rayrc_data_dir}/python"

    if [[ -x "${__rayrc_bin_dir}/uv" ]]; then
        return 0
    fi

    ## Official installer auto-detects OS/arch (incl. musl vs glibc).
    ## UV_INSTALL_DIR drops just the `uv`/`uvx` binaries into libs/bin (flat
    ## layout, no env script) while keeping `uv self update` working. Unlike
    ## UV_UNMANAGED_INSTALL it leaves the self-updater enabled; the only extra
    ## file is the update receipt at ~/.config/uv/uv-receipt.json.
    ## UV_NO_MODIFY_PATH stops it from editing shell rc files — rayrc owns PATH.
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
