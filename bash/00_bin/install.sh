#!/usr/bin/env bash

__rayrc_install() {
    local __rayrc_ctl_dir
    #
    # defined in ROOT/bash/install.sh as if it is global.
    # local __rayrc_bin_dir
    #

    __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_bin_dir="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"

    [[ ! -d "${__rayrc_bin_dir}" ]] && mkdir -p "${__rayrc_bin_dir}"
}

__rayrc_install
unset -f __rayrc_install
