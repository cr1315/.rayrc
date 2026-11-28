#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup

    ## per-host snippets kept out of the repo; the bash counterparts are ~/per_project_*.sh
    local f
    for f in "${HOME}"/per_project_*.zsh(N); do
        source "$f"
    done
}

__rayrc_main
unset -f __rayrc_main
