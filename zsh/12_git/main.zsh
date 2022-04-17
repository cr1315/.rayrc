#!/usr/bin/env zsh

__rayrc_main_git() {
    local __rayrc_dir_ctl_git
    local __rayrc_dir_data_git


    __rayrc_dir_ctl_git=$1
    # echo "\${__rayrc_dir_ctl_git}: ${__rayrc_dir_ctl_git}"

    __rayrc_dir_data_git="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_git}: ${__rayrc_dir_data_git}"


    source "$__rayrc_dir_ctl_git/forgit.plugin.zsh"

}

__rayrc_main_git ${0:A:h}
unset -f __rayrc_main_git
