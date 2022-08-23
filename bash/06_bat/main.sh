#!/usr/bin/env bash

command -v bat >/dev/null 2>&1 || { return; }

__rayrc_main() {
	__rayrc_module_common_setup

    alias bat="bat --color always"
    alias cat="bat"

}

__rayrc_main
unset -f __rayrc_main

