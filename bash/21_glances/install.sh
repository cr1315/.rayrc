#!/usr/bin/env bash

command -v glances >/dev/null 2>&1 && { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    python3 -m venv "${__rayrc_data_dir}"
    (
        source "${__rayrc_data_dir}/bin/activate"
        pip install --upgrade pip
        pip install glances[all]
    ) >&/dev/null

    ln -snf "${__rayrc_data_dir}/bin/glances" "${__rayrc_bin_dir}/glances"
}

__rayrc_install
unset -f __rayrc_install
