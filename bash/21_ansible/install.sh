#!/usr/bin/env bash

command -v python3 >/dev/null 2>&1 || { return; }
command -v ansible >/dev/null 2>&1 && { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    python3 -m venv "${__rayrc_data_dir}"
    (
        source "${__rayrc_data_dir}/bin/activate"
        pip install 'ansible<2.10.0'
    ) >&/dev/null

    ln -snf "${__rayrc_data_dir}/bin/ansible" "${__rayrc_bin_dir}/ansible"
    ln -snf "${__rayrc_data_dir}/bin/ansible-playbook" "${__rayrc_bin_dir}/ansible-playbook"
}

__rayrc_install
unset -f __rayrc_install
