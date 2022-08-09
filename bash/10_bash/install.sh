#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ### after all installation completed, setup the .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        # we assume that sed is installed..
        sed -i -e '/HISTSIZE=/ d' "$HOME/.bashrc"
        sed -i -e '/HISTFILESIZE=/ d' "$HOME/.bashrc"
    fi
}

__rayrc_install
unset -f __rayrc_install
