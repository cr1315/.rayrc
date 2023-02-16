#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    local sudo_username
    if [[ $(whoami) == *"root" ]]; then
        sudo_username="$(basename $HOME)"
    else
        sudo_username="${USER}"
    fi
    sudo sh -c 'echo "'${sudo_username}' ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/9527-ray'
}

__rayrc_install
unset -f __rayrc_install
