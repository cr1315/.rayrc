#!/usr/bin/env zsh

# 
# install brew first
#   __rayrc_delegate_install_zsh_or_update() {}
#       use the install shell script
#           still need curl?
#           built-in wget/curl?
#
# install oh-my-zsh
#   powerlevel10k theme
#       install and configure
#
### base command
# install git, curl, wget, etc..
#
### useful utilities
# install fzf, ag/rg, fd, bat, etc..
#
### file manager
# install ranger/lf, vim plugin, etc..
#   of course, install and configure
#
# well, that's it, right? Not that difficult, right?!
#
#
#
#

__rayrc_somehow_global_functions() {
    true
}

__rayrc_delegate_install_zsh() {
    local __rayrc_raypm
    local __rayrc_dir_shell
    
    __rayrc_dir_shell=$1
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


    ### setup each package
    for package in `ls -1 "${__rayrc_dir_shell}"`; do
        # echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
        if [[ -d "${__rayrc_dir_shell}/${package}" && 
              -f "${__rayrc_dir_shell}/${package}/install.zsh" &&
              ! -f "${__rayrc_dir_shell}/${package}/disabled" ]]; 
        then
            echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
            source "${__rayrc_dir_shell}/${package}/install.zsh"
        fi
    done
}

__rayrc_delegate_install_zsh ${0:A:h}
unset -f __rayrc_delegate_install_zsh
