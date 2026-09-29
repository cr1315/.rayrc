#!/usr/bin/env bash

command -v stu >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## config.toml, keybindings.toml, logs, preview themes/syntaxes live here
    export STU_ROOT_DIR="${__rayrc_data_dir}/config"

}

__rayrc_main
unset -f __rayrc_main
