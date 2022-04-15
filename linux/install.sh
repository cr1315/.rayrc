#!/usr/bin/env bash

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

	#
	# would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
	#
	# for EC2:
	#   `sudo dmidecode --string system-uuid'
	#   or `cat /sys/hypervisor/uuid'
	# TODO: case switch


	### auto setup
	for dir in `ls -1 "${__rayrc_linux_install_dir}"`; do

		# echo "\${__rayrc_linux_install_dir}/\${dir}: ${__rayrc_linux_install_dir}/${dir}"
		if [[ -d "${__rayrc_linux_install_dir}/${dir}" && -f "${__rayrc_linux_install_dir}/${dir}/install.sh" ]]; then
			source "${__rayrc_linux_install_dir}/${dir}/install.sh"
		fi

	done


	### after all installation completed, setup the .bashrc
	### can we assume grep installed?
	if [[ -f "$HOME/.bashrc" ]]; then
		if grep -q '.rayrc' "$HOME/.bashrc"; then
			# we assume sed installed..
			sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/bashrc"

# use here document to add two lines
cat <<EOF >> $HOME/.bashrc

[[ -f "${__rayrc_linux_install_dir}/main.sh" ]] && source "${__rayrc_linux_install_dir}/main.sh"
EOF

		fi
	fi

}


__rayrc_linux_install
unset -f __rayrc_linux_install
