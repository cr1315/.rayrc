#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup

    source "$__rayrc_ctl_dir/forgit.plugin.zsh"

}

__rayrc_main ${0:A:h}
unset -f __rayrc_main
