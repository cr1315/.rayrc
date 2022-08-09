#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ ${__rayrc_facts_os_type} == "linux" ]]; then
        __rayrc_github_downloader "stedolan/jq" "${__rayrc_data_dir}/jq" "linux64"
    else
        __rayrc_github_downloader "stedolan/jq" "${__rayrc_data_dir}/jq" "osx"
    fi

    mv -f "${__rayrc_data_dir}/jq" "${__rayrc_bin_dir}"
    chmod -R 755 "${__rayrc_bin_dir}"
    rm -rf "${__rayrc_data_dir}/jq"*

}

__rayrc_install
unset -f __rayrc_install
