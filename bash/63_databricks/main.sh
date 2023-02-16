#!/usr/bin/env bash

command -v databricks >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    if [[ -f "${HOME}/.databricksenv" ]]; then
        source "${HOME}/.databricksenv"
    fi
}

__rayrc_main
unset -f __rayrc_main
