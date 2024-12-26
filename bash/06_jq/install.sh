#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "linux" "arm64"
        elif uname -m | grep -E -q "64" >&/dev/null; then
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "linux64"
        elif uname -m | grep -E -q "86" >&/dev/null; then
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "linux" "i386"
        else
            echo ".rayrc: unsupported cpu architecture for downloading jq.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "osx"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "macos" "arm64"
        else
            echo ".rayrc: unsupported cpu architecture for downloading jq.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading jq.."
        return 8
    fi

    if [[ -f "${__rayrc_data_dir}/jq" ]]; then
        mv -f "${__rayrc_data_dir}/jq" "${__rayrc_bin_dir}"
        chmod -R 755 "${__rayrc_bin_dir}"
        rm -rf "${__rayrc_data_dir}/jq"*
    fi
}

__rayrc_install
unset -f __rayrc_install
