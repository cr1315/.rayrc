#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }

__rayrc_main_vim() {
    local __rayrc_dir_ctl_vim
    local __rayrc_dir_data_vim

    __rayrc_dir_ctl_vim="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_vim}: ${__rayrc_dir_ctl_vim}"

    __rayrc_dir_data_vim="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_vim}: ${__rayrc_dir_data_vim}"

}

__rayrc_main_vim
unset -f __rayrc_main_vim
