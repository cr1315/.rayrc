#!/usr/bin/env zsh


__rayrc_somehow_global_functions() {
    true
}

__rayrc_delegate_install_zsh() {
    local __rayrc_raypm
    local __rayrc_dir_shell

	local __rayrc_dir_data_bin

    __rayrc_dir_shell=$1
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


    ### setup each package
    for package in `ls -1 "${__rayrc_dir_shell}"`; do
        # echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
        if [[ -d "${__rayrc_dir_shell}/${package}" &&
              -f "${__rayrc_dir_shell}/${package}/install.zsh" &&
              ! -f "${__rayrc_dir_shell}/${package}/disabled" ]];
        then
            # echo "\${__rayrc_dir_shell}/\${package}: ${__rayrc_dir_shell}/${package}"
            echo ""
            echo ".rayrc: setting up for ${package:3}.."
            source "${__rayrc_dir_shell}/${package}/install.zsh"
        fi
    done


	### after all installation completed, setup the .zshrc
	### can we assume grep installed?
	if [[ -f "$HOME/.zshrc" ]]; then
		if grep -q '.rayrc' "$HOME/.zshrc"; then
			# we assume sed installed..
			sed -i -e '/\.rayrc.*main\.sh/ d' "$HOME/.zshrc"
        fi

# use here document to add two lines
"cat" <<EOF >> $HOME/.zshrc

[[ -f "${__rayrc_dir_shell}/main.zsh" ]] && source "${__rayrc_dir_shell}/main.zsh"
EOF

		# "cat" $HOME/.zshrc
		echo ""
		echo ".rayrc: all done!"
		echo ".rayrc: please logout & login to enjoy your new shell environment!"
	fi

}

__rayrc_delegate_install_zsh ${0:A:h}
unset -f __rayrc_delegate_install_zsh
