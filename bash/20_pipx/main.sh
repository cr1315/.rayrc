#!/usr/bin/env bash

command -v pipx >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export PIPX_HOME="${__rayrc_data_dir}"
    export PIPX_BIN_DIR="${__rayrc_bin_dir}"

    eval "$(${__rayrc_data_dir}/boot/bin/register-python-argcomplete pipx)"
}

__rayrc_main
unset -f __rayrc_main
