#!/usr/bin/env bash

## httpie is a Python app: install it with uv tool, like pipx / poetry (same in every dialect).
## UV_TOOL_DIR / UV_TOOL_BIN_DIR are exported by 20_python/01_uv during the same install.
[[ -x "${__rayrc_bin_dir}/uv" && -n "${UV_TOOL_DIR}" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    ## look at uv's venv, not at `http`: older installs put the standalone binary from
    ## packages.httpie.io (Linux) at libs/bin/http, which `--force` replaces
    if [[ ! -d "${UV_TOOL_DIR}/httpie" ]]; then
        "${__rayrc_bin_dir}/uv" tool install --force --python 3.13 httpie >&/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
