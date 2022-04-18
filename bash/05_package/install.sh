#!/usr/bin/env bash


__rayrc_install_raypm() {
    local __rayrc_dir_ctl_raypm
    local __rayrc_dir_data_raypm


    __rayrc_dir_ctl_raypm="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_raypm}: ${__rayrc_dir_ctl_raypm}"

    __rayrc_dir_data_raypm="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_raypm}: ${__rayrc_dir_data_raypm}"


	if [[ "$__rayrc_stat_os" == "linux" ]]; then
        # determine distribution name from
        #   - `uname -a`
        #   - `cat /etc/os-relase`
        # set the corresponding package-manager to __rayrc_raypm
        true

	elif [[ "$__rayrc_stat_os" == "macos" ]]; then
        # install brew for macos is not installed
        if ! command -v brew >& /dev/null; then
            `which bash` -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        __rayrc_raypm="brew"
	else
		echo ".rayrc: not supported OS by now.."
		return 8
	fi

    # we need git, curl, etc A.S.A.P.
    if ! command -v git >& /dev/null; then
        ${__rayrc_raypm} install -y git
    fi
    if ! command -v curl >& /dev/null; then
        ${__rayrc_raypm} install -y curl
    fi
}

__rayrc_install_raypm
unset -f __rayrc_install_raypm


