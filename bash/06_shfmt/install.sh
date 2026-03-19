#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_eget_install "mvdan/sh" "shfmt" || return 8
}

__rayrc_install
unset -f __rayrc_install
