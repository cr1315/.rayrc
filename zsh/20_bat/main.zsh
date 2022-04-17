#!/usr/bin/env zsh

__rayrc_bat_setup() {
	local __rayrc_bat_setup_dir=$1
    # echo "\$__rayrc_bat_setup_dir: $__rayrc_bat_setup_dir"

	# set env variables for brew? fzf? rg? fd? bat? ranger?
    export BAT_CONFIG_PATH="$__rayrc_bat_setup_dir/config/bat.conf"

    # use bat as MANPAGER
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"

    # set aliases
    alias cat=bat

}

__rayrc_bat_setup ${0:A:h}
unset -f __rayrc_bat_setup
