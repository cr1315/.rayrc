#!/usr/bin/env zsh

command -v pnpm >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## $PNPM_HOME/bin is a symlink to libs/bin (see install.zsh)
    export PNPM_HOME="${__rayrc_data_dir}"

    ## completion needs compinit, which rayrc does not run itself
    (( ${+functions[compdef]} )) && eval "$(pnpm completion zsh)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
