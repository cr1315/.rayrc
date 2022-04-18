#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }


__rayrc_main_vim() {
	local __rayrc_main_vim_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_main_vim_setup_dir: ${__rayrc_vim_dir}"



}

__rayrc_main_vim
unset -f __rayrc_main_vim

