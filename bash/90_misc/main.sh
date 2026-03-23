#!/usr/bin/env bash

__rayrc_main() {
    __rayrc_module_common_setup

    for f in "${HOME}"/per_project_*.sh; do
        [[ -f "$f" ]] && source "$f"
    done

}

__rayrc_main
unset -f __rayrc_main
