#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup

    # set PATH

    # set env variables for brew? fzf? rg? fd? bat? ranger?

    # set env for zsh-completion

    # make .rayrc an oh-my-zsh plugin??
    # that would be so cool, right?
    # TODO: don't know why, but after run cmpinit, no effect

}

__rayrc_main {0:A:h}
unset -f __rayrc_main
