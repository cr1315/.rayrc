#!/usr/bin/env zsh

__rayrc_main() {
    local __rayrc_ctl_dir
    local __rayrc_data_dir

    __rayrc_ctl_dir=$1
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_data_dir}: ${__rayrc_data_dir}"

    # set env variables for brew? fzf? rg? fd? bat? ranger?
    export BAT_CONFIG_PATH="$__rayrc_data_dir/config/bat.conf"

    # use bat as MANPAGER
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"

    # set aliases
    alias cat=bat

}

__rayrc_main ${0:A:h}
unset -f __rayrc_main
