#!/usr/bin/env bash


__rayrc_install_jq() {
    local __rayrc_dir_ctl_jq
    local __rayrc_dir_data_jq


    __rayrc_dir_ctl_jq="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_jq}: ${__rayrc_dir_ctl_jq}"

    __rayrc_dir_data_jq="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_jq}: ${__rayrc_dir_data_jq}"
    [[ ! -d "${__rayrc_dir_data_jq}" ]] && mkdir -p "${__rayrc_dir_data_jq}"

    if [[ ${__rayrc_stat_os} == "linux" ]]; then
        __rayrc_github_downloader "stedolan/jq" "${__rayrc_dir_data_jq}/jq" "linux64"
    else
        __rayrc_github_downloader "stedolan/jq" "${__rayrc_dir_data_jq}/jq" "osx"
    fi

    mv -f "${__rayrc_dir_data_jq}/jq" "${__rayrc_dir_data_bin}"
    chmod -R 755 "${__rayrc_dir_data_bin}"

}

__rayrc_install_jq
unset -f __rayrc_install_jq


