#!/usr/bin/env zsh

command -v vim >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export EDITOR=vim
}

__rayrc_main
unset -f __rayrc_main
