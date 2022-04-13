#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }


__rayrc_vim_setup() {
	local __rayrc_vim_setup_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_vim_setup_dir: ${__rayrc_vim_setup_dir}"



}

__rayrc_vim_setup
unset -f __rayrc_vim_setup

