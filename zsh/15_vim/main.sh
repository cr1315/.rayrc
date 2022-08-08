#!/usr/bin/env zsh

__rayrc_main_vim() {
    local __rayrc_dir_ctl_vim
    local __rayrc_dir_data_vim

    __rayrc_dir_ctl_vim=$1
    # echo "\${__rayrc_dir_ctl_vim}: ${__rayrc_dir_ctl_vim}"

    __rayrc_dir_data_vim="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_vim}: ${__rayrc_dir_data_vim}"

    # set PATH

    # set env variables for brew? fzf? rg? fd? bat? ranger?

    # set env for zsh-completion

    # make .rayrc an oh-my-zsh plugin??
    # that would be so cool, right?
    # TODO: don't know why, but after run cmpinit, no effect

}

__rayrc_main_vim {0:A:h}
unset -f __rayrc_main_vim
