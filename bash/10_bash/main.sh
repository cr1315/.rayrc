#!/usr/bin/env bash

if [[ $(whoami) == *"root" ]]; then
    export USER="$(basename $HOME)"

    ## mangle /etc/profile settings
    export MAIL="/var/spool/mail/$USER"
else
    true
fi

# smile_prompt github
function smile_prompt {
    if [ "$?" -eq "0" ]; then
        SC="\[\033[32m\]:)"
    else
        SC="\[\033[31m\]:("
    fi
    PS1="\[\033[33m\]$USER\[\033[35m\]@\h \[\033[34m\]$PWD\[\033[00m\]\n$SC\[\033[00m\] "
}
PROMPT_COMMAND=smile_prompt

# color scheme for man, less, etc..
export GROFF_NO_SGR=1
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
export TERM="xterm-256color"

## set for perl in __rayrc_github_downloader
## now, given up using perl to extract words..
# export LC_CTYPE=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:erasedups

# aliases
if command -v exa >/dev/null 2>&1; then
    alias la="exa -ahl"
    alias ll="exa -hl"
    alias lt="exa -hlT"
else
    alias la="ls -Ahl"
    alias ll="ls -hl"
fi

alias cls="clear"
alias pd="pushd"
alias ds="dirs -v"
alias view="vim -R"
alias vi="vim"

alias ip="ip -c"

if [[ -t 0 && $- = *i* ]]; then
    stty -ixon
fi

__rayrc_main() {
    __rayrc_module_common_setup

    source "${__rayrc_ctl_dir}/functions.sh"

}

__rayrc_main
unset -f __rayrc_main
