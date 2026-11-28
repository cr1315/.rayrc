#!/usr/bin/env bash

__rayrc_main() {
    __rayrc_module_common_setup

    ## pnpm and the bins of `pnpm add -g` packages live in $PNPM_HOME/bin (see install.sh)
    [[ -x "${__rayrc_data_dir}/bin/pnpm" ]] || return 0

    ## pnpm locates its global dir, store and global bin dir via PNPM_HOME
    export PNPM_HOME="${__rayrc_data_dir}"
    if [[ ":${PATH}:" != *":${PNPM_HOME}/bin:"* ]]; then
        export PATH="${PNPM_HOME}/bin${PATH:+:${PATH}}"
    fi

    eval "$(pnpm completion bash)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
