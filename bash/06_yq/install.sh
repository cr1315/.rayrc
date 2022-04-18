#!/usr/bin/env bash


__rayrc_install_yq() {
    local __rayrc_dir_ctl_yq
    local __rayrc_dir_data_yq


    __rayrc_dir_ctl_yq="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_yq}: ${__rayrc_dir_ctl_yq}"

    __rayrc_dir_data_yq="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_yq}: ${__rayrc_dir_data_yq}"
    [[ ! -d "${__rayrc_dir_data_yq}" ]] && mkdir -p "${__rayrc_dir_data_yq}"


    if [[ ${__rayrc_stat_os} == "linux" ]]; then
        __rayrc_github_downloader "mikefarah/yq" "${__rayrc_dir_data_yq}/yq" 'linux_amd64"'
    else
        __rayrc_github_downloader "mikefarah/yq" "${__rayrc_dir_data_yq}/yq" 'darwin_arm64"'
    fi

    mv -f "${__rayrc_dir_data_yq}/yq" "${__rayrc_dir_data_bin}"
    chmod -R 755 "${__rayrc_dir_data_bin}"
}

__rayrc_install_yq
unset -f __rayrc_install_yq


