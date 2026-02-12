#!/usr/bin/env bash

__rayrc_main() {
    __rayrc_module_common_setup

    source "${HOME}/per_project_*.sh"

}

__rayrc_main
unset -f __rayrc_main
