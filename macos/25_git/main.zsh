#!/usr/bin/env zsh

__rayrc_git_setup() {
    local __rayrc_git_setup_dir=$1
    # echo "\$__rayrc_git_setup_dir: $__rayrc_git_setup_dir"


    # source "$__rayrc_git_setup_dir/functions.zsh"
    source "$__rayrc_git_setup_dir/forgit.plugin.zsh"

}

__rayrc_git_setup ${0:A:h}
unset -f __rayrc_git_setup
