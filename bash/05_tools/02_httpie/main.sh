#!/usr/bin/env bash

command -v http >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export HTTPIE_CONFIG_DIR="${__rayrc_data_dir}/httpie"

}

__rayrc_main
unset -f __rayrc_main
