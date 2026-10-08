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


__rayrc_main() {
    __rayrc_module_common_setup

    alias cls="clear"
    alias ds="dirs -v"
    alias pd="pushd"
    alias vi="vim"
    alias view="vim -R"

    alias ip="ip -c"


    # -t 0: stdin が端末に接続されている（パイプ/Ansible では false）
    # $- = *i*: インタラクティブシェル
    # stty -ixon: Ctrl+S/Ctrl+Q のXON/XOFFフロー制御を無効化 → Ctrl+S を他のキーバインドに使える
    if [[ -t 0 && $- = *i* ]]; then
        stty -ixon
    fi

    source "${__rayrc_ctl_dir}/functions.sh"
    source "${__rayrc_ctl_dir}/exports.sh"
}

__rayrc_main
unset -f __rayrc_main
