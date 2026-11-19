#!/usr/bin/env bash

command -v pnpm >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## pnpm locates its global dir, store and global bin dir via PNPM_HOME;
    ## $PNPM_HOME/bin is a symlink to libs/bin (see install.sh).
    export PNPM_HOME="${__rayrc_data_dir}"

    eval "$(pnpm completion bash)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
