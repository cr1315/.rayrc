#!/usr/bin/env bash

command -v python3 >/dev/null 2>&1 || { return; }


__rayrc_main_ranger() {
	local __rayrc_main_ranger_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_main_ranger_setup_dir: ${__rayrc_ranger_dir}"

    export PYTHONPATH="${__rayrc_main_ranger_setup_dir}/packages:${__rayrc_ranger_dir}/lib-dyaload${PYTHONPATH:+:${PYTHONPATH}}"

}

__rayrc_main_ranger
unset -f __rayrc_main_ranger

