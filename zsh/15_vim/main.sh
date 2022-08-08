#!/usr/bin/env zsh

__rayrc_main() {
    local __rayrc_ctl_dir
    local __rayrc_data_dir

    __rayrc_ctl_dir=$1
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_data_dir}: ${__rayrc_data_dir}"

    # set PATH

    # set env variables for brew? fzf? rg? fd? bat? ranger?

    # set env for zsh-completion

    # make .rayrc an oh-my-zsh plugin??
    # that would be so cool, right?
    # TODO: don't know why, but after run cmpinit, no effect

}

__rayrc_main {0:A:h}
unset -f __rayrc_main
