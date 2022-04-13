#!/usr/bin/env bash

command -v python3 >/dev/null 2>&1 || { return; }


__rayrc_ranger_setup() {
	local __rayrc_ranger_setup_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_ranger_setup_dir: ${__rayrc_ranger_setup_dir}"

    export PYTHONPATH="${__rayrc_ranger_setup_dir}/packages:${__rayrc_ranger_setup_dir}/lib-dyaload${PYTHONPATH:+:${PYTHONPATH}}"

}

__rayrc_ranger_setup
unset -f __rayrc_ranger_setup

