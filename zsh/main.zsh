#!/usr/bin/env zsh


__rayrc_delegate_main() {
    local __rayrc_raypm
    local __rayrc_dir_shell

	local __rayrc_dir_base
	local __rayrc_dir_libs
	local __rayrc_dir_data_bin

    __rayrc_dir_shell=$1
    echo "\${__rayrc_dir_shell}: ${__rayrc_dir_shell}"

	# actually, this was a bug...
	# I couldn't calculate this much..
	__rayrc_dir_base="$(cd -- "${__rayrc_dir_shell}/.." && pwd -P)"
	__rayrc_dir_libs="$(cd -- "${__rayrc_dir_shell}/../libs" && pwd -P)"


    # determine the os type and set __rayrc_stat_os
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		__rayrc_stat_os="linux"
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		__rayrc_stat_os="macos"
	else
		echo ".rayrc: not supported OS by now.."
		return 8
	fi


    ### setup each package
    for package in `ls -1 "${__rayrc_dir_shell}"`; do
        # echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
        if [[ -d "${__rayrc_dir_shell}/${package}" &&
              -f "${__rayrc_dir_shell}/${package}/main.zsh" &&
              ! -f "${__rayrc_dir_shell}/${package}/disabled" ]];
        then
            echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
            source "${__rayrc_dir_shell}/${package}/main.zsh"
        fi
    done

}

__rayrc_delegate_main ${0:A:h}
unset -f __rayrc_delegate_main
