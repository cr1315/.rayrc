#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup
    __rayrc_source_facade install
}

__rayrc_install
unset -f __rayrc_install
