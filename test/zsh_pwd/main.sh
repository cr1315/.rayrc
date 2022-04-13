#!/usr/bin/env zsh



current_dir=${0:A:h}
echo $current_dir


__rayrc_main() {
	local current_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "current_dir: ${current_dir}"
	if [[ ! "$PATH" == *"${current_dir}"/00_bin* ]]; then
		export PATH="${current_dir}"/00_bin"${PATH:+:${PATH}}"
	fi

	### auto setup
	for dir in `ls -1 "${current_dir}"`; do
		# echo "\$current_dir/\$dir: $current_dir/$dir"
		if [[ -d "$current_dir/$dir" && -f "$current_dir/$dir/main.sh" ]]; then
			source "$current_dir/$dir/main.sh"
		fi
	done
}


unset -f __rayrc_main
