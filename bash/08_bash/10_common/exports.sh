#!/usr/bin/env bash

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
export COLORTERM="truecolor"

## set for perl in __rayrc_github_downloader
## now, given up using perl to extract words..
# export LC_CTYPE=en_US.UTF-8
if locale -a 2>/dev/null | grep -qiE 'en_US\.utf.?8'; then
    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
fi
## disable perl warning message for some docker envs
export PERL_BADLANG=0

export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
shopt -u histappend
