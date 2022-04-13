#!/usr/bin/env bash

# actually, we even don't need this much
# and as by times, we don't even have git installed, or we don't have Internet connected..

# we would need to bring compiled bins to the workstation..
# then it would be boring to prepare for the target platform? CPU type? etc..

# well, but, THAT IS NOT A REASON TO NOT WRITE BEAUTIFUL CODE!!!
# at least, write beautiful code that would be worked as assumed!
# coding is just a hard work! -> It's you who make it an artifact!


# determine if there is git installed

__rayrc_linux_install() {
	# SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
	local __rayrc_linux_install_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_linux_install_dir: ${__rayrc_linux_install_dir}"

    ### setup bashrc
    cat <<EOF >> $HOME/.bashrc

[[ -f "${__rayrc_linux_install_dir}/main.sh" ]] && source "${__rayrc_linux_install_dir}/main.sh"
EOF

	### auto setup
	for dir in `ls -1 "${__rayrc_linux_install_dir}"`; do
		# echo "\$__rayrc_linux_install_dir/\$dir: $__rayrc_linux_install_dir/$dir"
		if [[ -d "$__rayrc_linux_install_dir/$dir" && -f "$__rayrc_linux_install_dir/$dir/install.sh" ]]; then
			source "$__rayrc_linux_install_dir/$dir/install.sh"
		fi
	done
}


__rayrc_linux_install
unset -f __rayrc_linux_install
