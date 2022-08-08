#!/usr/bin/env zsh

__rayrc_main_bat() {
    local __rayrc_dir_ctl_bat
    local __rayrc_dir_data_bat

    __rayrc_dir_ctl_bat=$1
    # echo "\${__rayrc_dir_ctl_bat}: ${__rayrc_dir_ctl_bat}"

    __rayrc_dir_data_bat="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_bat}: ${__rayrc_dir_data_bat}"

    # set env variables for brew? fzf? rg? fd? bat? ranger?
    export BAT_CONFIG_PATH="$__rayrc_dir_data_bat/config/bat.conf"

    # use bat as MANPAGER
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"

    # set aliases
    alias cat=bat

}

__rayrc_main_bat ${0:A:h}
unset -f __rayrc_main_bat
