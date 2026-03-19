#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_eget_install "dundee/gdu" "gdu" --asset "gdu_linux_amd64.tgz" || return 8
}

__rayrc_install
unset -f __rayrc_install
