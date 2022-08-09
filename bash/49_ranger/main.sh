#!/usr/bin/env bash

command -v python3 >/dev/null 2>&1 || { return; }

__rayrc_main() {
	__rayrc_module_common_setup
}

__rayrc_main
unset -f __rayrc_main
