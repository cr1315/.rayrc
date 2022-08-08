#!/usr/bin/env bash

command -v python3 >/dev/null 2>&1 || { return; }

__rayrc_main() {
	__rayrc_common_setup_module

	export PYTHONPATH="${__rayrc_ctl_dir}/packages:${__rayrc_ranger_dir}/lib-dyaload${PYTHONPATH:+:${PYTHONPATH}}"
}

__rayrc_main
unset -f __rayrc_main
