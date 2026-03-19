#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_eget_install "mikefarah/yq" "yq" --asset "linux" --asset ".tar.gz" || return 8
}

__rayrc_install
unset -f __rayrc_install
