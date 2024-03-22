#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "arm64.tgz" "linux"
        elif uname -m | grep -E -q "ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "amd64.tgz" "linux"
        elif uname -m | grep -E -q "86" >&/dev/null; then
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "386.tgz" "linux"
        else
            echo ".rayrc: unsupported cpu architecture for downloading gdu.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "darwin" "amd64.tgz"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "darwin" "arm64.tgz"
        else
            echo ".rayrc: unsupported cpu architecture for downloading gdu.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading gdu.."
        return 8
    fi

    tar xf "${__rayrc_data_dir}/gdu.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:gdu:'

    cp -f "${__rayrc_data_dir}/gdu" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/gdu"*
}

__rayrc_install
unset -f __rayrc_install
