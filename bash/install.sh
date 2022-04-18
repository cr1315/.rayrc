#!/usr/bin/env bash

# we would need to bring compiled bins to the workstation..
# then it would be boring to prepare for the target platform? CPU type? etc..

# well, but, THAT IS NOT A REASON TO NOT WRITE BEAUTIFUL CODE!!!
# at least, write beautiful code that would be worked as assumed!
# coding is just a hard work! -> It's you who make it an artifact!

# determine if there is git installed

__rayrc_url_downloader() {
	true
}


__rayrc_delegate_install_bash() {
    local __rayrc_raypm
    local __rayrc_dir_shell

    __rayrc_dir_shell="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    echo "\${__rayrc_dir_shell}: ${__rayrc_dir_shell}"


    # determine the os type and set __rayrc_stat_os
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		__rayrc_stat_os="linux"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		__rayrc_stat_os="macos"
	else
		echo ".rayrc: not supported OS by now.."
		return 8
	fi


	#
	# would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
	#
	# for EC2:
	#   `sudo dmidecode --string system-uuid'
	#   or `cat /sys/hypervisor/uuid'
	# TODO: case switch


	### auto setup
	for package in `ls -1 "${__rayrc_dir_shell}"`; do

		echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
		if [[ -d "${__rayrc_dir_shell}/${package}" && -f "${__rayrc_dir_shell}/${package}/install.sh" ]]; then
			source "${__rayrc_dir_shell}/${package}/install.sh"
		fi

	done


	### after all installation completed, setup the .bashrc
	### can we assume grep installed?
	if [[ -f "$HOME/.bashrc" ]]; then
		if grep -q '.rayrc' "$HOME/.bashrc"; then
			# we assume sed installed..
			sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.bashrc"

# use here document to add two lines
cat <<EOF >> $HOME/.bashrc

[[ -f "${__rayrc_dir_shell}/main.sh" ]] && source "${__rayrc_dir_shell}/main.sh"
EOF

		fi
	fi

}


__rayrc_delegate_install_bash
unset -f __rayrc_delegate_install_bash
