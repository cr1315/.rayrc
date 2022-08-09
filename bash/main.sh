#!/usr/bin/env bash

__rayrc_delegate_main() {
	## declare global variables here
	##   as our goal is to do all the things on the fly, I'll try to EXPORT nothing in the implementation
	local __rayrc_package_manager
	local __rayrc_bin_dir

	local __rayrc_delegate_dir
	__rayrc_delegate_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "\${__rayrc_delegate_dir}: ${__rayrc_delegate_dir}"

	local __rayrc_root_dir
	__rayrc_root_dir="$(cd -- "${__rayrc_delegate_dir}/.." && pwd -P)"
	local __rayrc_libs_dir
	__rayrc_libs_dir="$(cd -- "${__rayrc_delegate_dir}/../libs" && pwd -P)"

	local __rayrc_ctl_dir
	local __rayrc_data_dir
	source "${__rayrc_delegate_dir}/module_common_setup.sh"

	# determine the os type and set __rayrc_facts_os_type
	local __rayrc_facts_os_type
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		__rayrc_facts_os_type="linux"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		__rayrc_facts_os_type="macos"
	else
		echo ""
		echo ".rayrc: not supported OS type for now.."
		echo ""
		return 8
	fi

	local __rayrc_facts_os_distribution
	#
	# would be better to determine if this is an EC2 instance, photon OS, ubuntu, CentOS
	#
	# for EC2:
	#   `sudo dmidecode --string system-uuid'
	#   `cat /sys/hypervisor/uuid'
	# TODO: case switch
	#       set __rayrc_facts_os_distribution
	#
	# or, create a function __rayrc_determin_os_distribution()
	#

	### auto setup
	echo ""
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
