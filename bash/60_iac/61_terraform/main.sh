#!/usr/bin/env bash

command -v terraform >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    alias tf="terraform"

    export TF_CLI_CONFIG_FILE="${__rayrc_data_dir}/.terraformrc"
    export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
    if [[ ! -d "${TF_PLUGIN_CACHE_DIR}" ]]; then
        mkdir -p "${TF_PLUGIN_CACHE_DIR}"
    fi
}

__rayrc_main
unset -f __rayrc_main
