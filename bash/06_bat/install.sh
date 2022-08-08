#!/usr/bin/env bash

__rayrc_install_bat() {
    local __rayrc_dir_ctl_bat
    local __rayrc_dir_data_bat

    __rayrc_dir_ctl_bat="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_bat}: ${__rayrc_dir_ctl_bat}"

    __rayrc_dir_data_bat="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_bat}: ${__rayrc_dir_data_bat}"
    [[ ! -d "${__rayrc_dir_data_bat}" ]] && mkdir -p "${__rayrc_dir_data_bat}"

    __rayrc_github_downloader "sharkdp/bat" "${__rayrc_dir_data_bat}/bat.tar.gz" \
        $(uname -m) $(echo -n $OSTYPE)

    tar xf "${__rayrc_dir_data_bat}/bat.tar.gz" -C "${__rayrc_dir_data_bat}" --transform 's:^[^/]*:bat:'

    cp -f "${__rayrc_dir_data_bat}/bat/bat" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_dir_data_bat}/bat"*
}

__rayrc_install_bat
unset -f __rayrc_install_bat
