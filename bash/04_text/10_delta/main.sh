#!/usr/bin/env bash

command -v delta >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    # set env variables
    export DELTA_FEATURES='+side-by-side'

}

__rayrc_main
unset -f __rayrc_main
