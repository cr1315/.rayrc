#!/usr/bin/env bash

__rayrc_install_jq() {
    local __rayrc_dir_ctl_jq
    local __rayrc_dir_data_jq

    __rayrc_dir_ctl_jq="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_jq}: ${__rayrc_dir_ctl_jq}"

    __rayrc_dir_data_jq="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_jq}: ${__rayrc_dir_data_jq}"
    [[ ! -d "${__rayrc_dir_data_jq}" ]] && mkdir -p "${__rayrc_dir_data_jq}"

    if [[ ${__rayrc_facts_os_type} == "linux" ]]; then
        __rayrc_github_downloader "stedolan/jq" "${__rayrc_dir_data_jq}/jq" "linux64"
    else
        __rayrc_github_downloader "stedolan/jq" "${__rayrc_dir_data_jq}/jq" "osx"
    fi

    mv -f "${__rayrc_dir_data_jq}/jq" "${__rayrc_bin_dir}"
    chmod -R 755 "${__rayrc_bin_dir}"
    rm -rf "${__rayrc_dir_data_jq}/jq"*

}

__rayrc_install_jq
unset -f __rayrc_install_jq
