#!/usr/bin/env bash


__rayrc_delegate_main() {
    local __rayrc_raypm
    local __rayrc_dir_shell

	local __rayrc_dir_bin

    __rayrc_dir_shell="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_shell}: ${__rayrc_dir_shell}"


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
	#   `cat /sys/hypervisor/uuid'
	# TODO: case switch
	#       set __rayrc_stat_os_dist


	### auto setup
	for package in `ls -1 "${__rayrc_dir_shell}"`; do

		# echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
		if [[ -d "${__rayrc_dir_shell}/${package}" && -f "${__rayrc_dir_shell}/${package}/main.sh" ]]; then
			source "${__rayrc_dir_shell}/${package}/main.sh"
		fi

	done
}


__rayrc_delegate_main
unset -f __rayrc_delegate_main
