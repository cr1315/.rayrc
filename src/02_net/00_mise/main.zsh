#!/usr/bin/env zsh

command -v mise >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## everything mise writes stays in libs/net/mise (same as main.sh)
    export MISE_DATA_DIR="${__rayrc_data_dir}/data"
    export MISE_CONFIG_DIR="${__rayrc_data_dir}/config"
    export MISE_GLOBAL_CONFIG_FILE="${MISE_CONFIG_DIR}/config.toml"
    export MISE_CACHE_DIR="${__rayrc_data_dir}/cache"
    export MISE_STATE_DIR="${__rayrc_data_dir}/state"
}

__rayrc_main
unset -f __rayrc_main
