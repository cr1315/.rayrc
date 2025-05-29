#!/usr/bin/env bash

command -v pipx >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export PIPX_HOME="${__rayrc_data_dir}/run"
    export PIPX_BIN_DIR="${__rayrc_bin_dir}"

    local pipx_full_path="$(readlink `which pipx`)"
    local pipx_complete_path="$(dirname $pipx_full_path)/register-python-argcomplete"
    if [[ -f "${pipx_complete_path}" ]]; then
        eval "$(${pipx_complete_path} pipx)"
    fi
}

__rayrc_main
unset -f __rayrc_main
