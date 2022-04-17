#!/usr/bin/env zsh

# shortcut


__rayrc_install_raypm() {
    local __rayrc_dir_ctl_raypm
    local __rayrc_dir_data_raypm


    __rayrc_dir_ctl_raypm=$1
    echo "\${__rayrc_dir_ctl_raypm}: ${__rayrc_dir_ctl_raypm}"

    __rayrc_dir_data_raypm="${__rayrc_dir_libs}/${1:t}"
    echo "\${__rayrc_dir_data_raypm}: ${__rayrc_dir_data_raypm}"

    echo "package: $package"

	if [[ "$__rayrc_stat_os" == "linux" ]]; then		
        # determine distribution name from 
        #   - `uname -a`
        #   - `cat /etc/os-relase`
        # set the corresponding package-manager to __rayrc_raypm

	elif [[ "$__rayrc_stat_os" == "macos" ]]; then
        # install brew for macos is not installed
        if ! command -v brew >& /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        __rayrc_raypm="brew"
	else
		echo ".rayrc: not supported OS by now.."
		return 8
	fi
}

__rayrc_install_raypm ${0:A:h}
unset -f __rayrc_install_raypm
