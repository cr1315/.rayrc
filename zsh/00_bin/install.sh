#!/usr/bin/env bash

__rayrc_install() {
    local __rayrc_ctl_dir
    #
    # defined in ROOT/bash/install.sh as it is global.
    # local __rayrc_bin_dir

    __rayrc_ctl_dir="$1"
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_bin_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_bin_dir}: ${__rayrc_bin_dir}"

    [[ ! -d "${__rayrc_bin_dir}" ]] && mkdir -p "${__rayrc_bin_dir}"
}

__rayrc_install ${0:A:h}
unset -f __rayrc_install
