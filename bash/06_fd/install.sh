#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "arm" "musl"
        elif uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "musl" "x86_64"
        else
            echo ".rayrc: unsupported cpu architecture for downloading exa.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "macos" "x86"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "macos" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading exa.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading exa.."
        return 8
    fi

    tar xf "${__rayrc_data_dir}/fd.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:fd:'

    cp -f "${__rayrc_data_dir}/fd/fd" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/fd"*
}

__rayrc_install
unset -f __rayrc_install
