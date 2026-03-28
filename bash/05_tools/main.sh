#!/usr/bin/env bash

__rayrc_main() {
    __rayrc_module_common_setup
    __rayrc_source_facade main
}

__rayrc_main
unset -f __rayrc_main
