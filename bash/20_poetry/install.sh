#!/usr/bin/env bash

command -v poetry >/dev/null 2>&1 && { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    curl -sSL https://install.python-poetry.org -o "${__rayrc_data_dir}/install_poetry.py"
    POETRY_HOME="${__rayrc_data_dir}" python3 "${__rayrc_data_dir}/install_poetry.py" --yes --force >&/dev/null

    ln -snf "${__rayrc_data_dir}/bin/poetry" "${__rayrc_bin_dir}/poetry"
}

__rayrc_install
unset -f __rayrc_install
