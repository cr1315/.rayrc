#!/usr/bin/env bash

command -v fnm >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## Node versions live under libs/nodejs/fnm. The per-shell symlinks that
    ## `fnm env` creates go to $XDG_RUNTIME_DIR/fnm_multishells (ephemeral).
    export FNM_DIR="${__rayrc_data_dir}"

    ## --use-on-cd switches Node by .node-version / .nvmrc / package.json;
    ## note that it does so by defining `alias cd=__fnmcd`.
    eval "$(fnm env --shell bash --use-on-cd)"
    eval "$(fnm completions --shell bash)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
