#!/usr/bin/env zsh

# make .rayrc an oh-my-zsh plugin??
# that would be so cool, right?
#     ==> NO, I'm the father / I'm the controller!!

__rayrc_main() {
    __rayrc_module_common_setup

    # set PATH

    # in zsh, ${0:A:p} -> full dir path?
    # mydir=${0:a:h}
    # SCRIPT_PATH="${0:A:h}"

    # set for History, size, cache file..
    #set history size
    export HISTSIZE=10000
    #save history after logout
    export SAVEHIST=100000
    #append into history file
    setopt INC_APPEND_HISTORY
    #save only one command if 2 common are same and consistent
    setopt HIST_IGNORE_DUPS
    #add timestamp for each entry
    setopt EXTENDED_HISTORY

    # set env variables for brew? fzf? rg? fd? bat? ranger?

    # set aliases
    source "${__rayrc_ctl_dir}/alias.zsh"

    # set env for zsh-completion
    # TODO: don't know why that there is no effect after run cmpinit

}

__rayrc_main
unset -f __rayrc_main
