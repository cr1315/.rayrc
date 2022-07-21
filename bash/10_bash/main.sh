#!/usr/bin/env bash

if [[ `whoami` == *"root" ]]; then
  export USER="$(basename $HOME)"
else
  true
fi


# smile_prompt github
function smile_prompt
{
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


export HISTSIZE=100000
export HISTFILESIZE=100000


# aliases
alias cls="clear"
alias la="ls -ahl"
alias ll="ls -hl"
alias pd="pushd"
alias ds="dirs -v"
alias view="vim -R"
alias vi="vim"
alias cat="bat"


showpath() {
  echo $PATH | sed -e 's/:/\n/g'
}

newips() {
  curl -sSL "https://ip-ranges.amazonaws.com/ip-ranges.json" | jq '[
    .prefixes[] |
    select(.service=="API_GATEWAY" and .region=="ap-northeast-1") |
    .ip_prefix
  ]'
}

