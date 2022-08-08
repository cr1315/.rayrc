#!/usr/bin/env zsh

__rayrc_main() {
    local __rayrc_ctl_dir
    local __rayrc_data_dir

    __rayrc_ctl_dir=$1
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_data_dir}: ${__rayrc_data_dir}"

    source "$__rayrc_ctl_dir/forgit.plugin.zsh"

}

__rayrc_main ${0:A:h}
unset -f __rayrc_main
