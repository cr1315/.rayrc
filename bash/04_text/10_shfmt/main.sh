#!/usr/bin/env bash

command -v shfmt >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    alias shfmt="shfmt -i 4"
}

__rayrc_main
unset -f __rayrc_main
