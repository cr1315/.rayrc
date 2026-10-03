#!/usr/bin/env bash

command -v uv >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export UV_TOOL_DIR="${__rayrc_data_dir}/tools"
    export UV_TOOL_BIN_DIR="${__rayrc_bin_dir}"
    export UV_PYTHON_INSTALL_DIR="${__rayrc_data_dir}/python"

    eval "$(uv generate-shell-completion bash)" 2>/dev/null
    eval "$(uvx --generate-shell-completion bash)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
