#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_common_setup_module
}

__rayrc_main
unset -f __rayrc_main
