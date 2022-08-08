#!/usr/bin/env bash

__rayrc_delegate_main() {
	local __rayrc_package_manager
	local __rayrc_delegate_dir

	local __rayrc_root_dir
	local __rayrc_libs_dir
	local __rayrc_bin_dir

	__rayrc_delegate_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "\${__rayrc_delegate_dir}: ${__rayrc_delegate_dir}"

	# actually, this was a bug...
	# I couldn't calculate this much..
	__rayrc_root_dir="$(cd -- "${__rayrc_delegate_dir}/.." && pwd -P)"
	__rayrc_libs_dir="$(cd -- "${__rayrc_delegate_dir}/../libs" && pwd -P)"

	# determine the os type and set __rayrc_facts_os_type
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		__rayrc_facts_os_type="linux"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		__rayrc_facts_os_type="macos"
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
	#       set __rayrc_facts_os_distribution

	### auto setup
	local __rayrc_package
	for __rayrc_package in $(ls -1 "${__rayrc_delegate_dir}"); do

		# echo "\${__rayrc_delegate_dir}/\${__rayrc_package}: ${__rayrc_delegate_dir}/${__rayrc_package}"
		if [[ -d "${__rayrc_delegate_dir}/${__rayrc_package}" && -f "${__rayrc_delegate_dir}/${__rayrc_package}/main.sh" ]]; then
			source "${__rayrc_delegate_dir}/${__rayrc_package}/main.sh"
		fi

	done
}

__rayrc_delegate_main
unset -f __rayrc_delegate_main
