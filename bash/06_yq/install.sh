#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_common_setup_module

    if [[ ${__rayrc_facts_os_type} == "linux" ]]; then
        __rayrc_github_downloader "mikefarah/yq" "${__rayrc_data_dir}/yq" 'linux_amd64"'
    else
        __rayrc_github_downloader "mikefarah/yq" "${__rayrc_data_dir}/yq" 'darwin_arm64"'
    fi

    mv -f "${__rayrc_data_dir}/yq" "${__rayrc_bin_dir}"
    chmod -R 755 "${__rayrc_bin_dir}"
    rm -rf "${__rayrc_data_dir}/yq"*
}

__rayrc_install
unset -f __rayrc_install
