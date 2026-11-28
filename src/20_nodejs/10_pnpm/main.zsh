#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup

    ## pnpm and the bins of `pnpm add -g` packages live in $PNPM_HOME/bin (see install.zsh)
    [[ -x "${__rayrc_data_dir}/bin/pnpm" ]] || return 0

    export PNPM_HOME="${__rayrc_data_dir}"
    if [[ ":${PATH}:" != *":${PNPM_HOME}/bin:"* ]]; then
        export PATH="${PNPM_HOME}/bin${PATH:+:${PATH}}"
    fi

    ## completion needs compinit, which rayrc does not run itself
    (( ${+functions[compdef]} )) && eval "$(pnpm completion zsh)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
