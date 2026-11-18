#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ### after all installation completed, setup the .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        # we assume that sed is installed..
        sed -i -e '/HISTSIZE=/ d' "$HOME/.bashrc"
        sed -i -e '/HISTFILESIZE=/ d' "$HOME/.bashrc"
    fi

    if [[ ! -f "$HOME/.bash_profile" && ! -f "$HOME/.profile" && ! -f "$HOME/.bash_login" ]]; then
        "cat" <<-EOF >>"$HOME/.bash_profile"
			if [ -f ~/.bashrc ]; then
				. ~/.bashrc
			fi
		EOF
    fi
}

__rayrc_install
unset -f __rayrc_install
