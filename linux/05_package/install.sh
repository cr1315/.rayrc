#!/usr/bin/env bash


__rayrc_pm_install() {
	local __rayrc_pm_install_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_pm_install_dir: ${__rayrc_pm_install_dir}"

    echo "current_os from sourced function: $current_os"

}

__rayrc_pm_install
unset -f __rayrc_pm_install


