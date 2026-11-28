#!/usr/bin/env zsh

command -v uv >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export UV_TOOL_DIR="${__rayrc_data_dir}/tools"
    export UV_TOOL_BIN_DIR="${__rayrc_bin_dir}"
    export UV_PYTHON_INSTALL_DIR="${__rayrc_data_dir}/python"
    ## uv-managed Pythons only: a venv on a system Python breaks when that Python is
    ## uninstalled or upgraded (the venv only points at it)
    export UV_MANAGED_PYTHON=1

    ## completion needs compinit, which rayrc does not run itself
    if (( ${+functions[compdef]} )); then
        eval "$(uv generate-shell-completion zsh)" 2>/dev/null
        eval "$(uvx --generate-shell-completion zsh)" 2>/dev/null
    fi
}

__rayrc_main
unset -f __rayrc_main
