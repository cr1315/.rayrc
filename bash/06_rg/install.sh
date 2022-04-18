#!/usr/bin/env bash


__rayrc_install_rg() {
    local __rayrc_dir_ctl_rg
    local __rayrc_dir_data_rg


    __rayrc_dir_ctl_rg="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_rg}: ${__rayrc_dir_ctl_rg}"

    __rayrc_dir_data_rg="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_rg}: ${__rayrc_dir_data_rg}"

    __rayrc_github_downloader "BurntSushi/ripgrep" "${__rayrc_dir_data_rg}/rg.tar.gz" \
        `uname -m` 'linux'
    tar xf "${__rayrc_dir_data_rg}/rg.tar.gz" --transform 's:^[^/]*:rg:'
    mv -f "${__rayrc_dir_data_rg}/rg/rg" "${__rayrc_dir_data_bin}"

    echo ""
    echo "after extract rg"
    ls -ahlR "${__rayrc_dir_data_rg}/rg"
    ls -ahl "${__rayrc_dir_data_bin}"
}

__rayrc_install_rg
unset -f __rayrc_install_rg


