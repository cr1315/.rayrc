#!/usr/bin/env bash

__rayrc_main() {
	# SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" >& /dev/null && pwd )"
	local __rayrc_main_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_main_dir: ${__rayrc_main_dir}"
	if [[ ! "$PATH" == *"${__rayrc_main_dir}"/00_bin* ]]; then
		export PATH="${__rayrc_main_dir}"/00_bin"${PATH:+:${PATH}}"
	fi

	### auto setup
	for dir in `ls -1 "${__rayrc_main_dir}"`; do
		# echo "\$__rayrc_main_dir/\$dir: $__rayrc_main_dir/$dir"
		if [[ -d "$__rayrc_main_dir/$dir" && -f "$__rayrc_main_dir/$dir/main.sh" ]]; then
			source "$__rayrc_main_dir/$dir/main.sh"
		fi
	done
}


__rayrc_main
unset -f __rayrc_main
