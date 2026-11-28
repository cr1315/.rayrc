#!/usr/bin/env zsh

command -v fnm >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## Node versions live under libs/nodejs/fnm (same as main.sh)
    export FNM_DIR="${__rayrc_data_dir}"

    ## --use-on-cd: in zsh this hooks chpwd (no `cd` alias as in bash)
    eval "$(fnm env --shell zsh --use-on-cd)"

    ## completion needs compinit, which rayrc does not run itself
    (( ${+functions[compdef]} )) && eval "$(fnm completions --shell zsh)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
