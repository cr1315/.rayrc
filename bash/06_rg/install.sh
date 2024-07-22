#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "x86_64" >&/dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "x86_64" 'musl.tar.gz"'
        elif uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "86" 'linux-gnu.tar.gz"'
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "arm" 'linux-musleabihf.tar.gz"'
        else
            echo ".rayrc: unsupported cpu architecture for downloading rg.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "darwin" "x86"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "linux" "aarch"
        else
            echo ".rayrc: unsupported cpu architecture for downloading rg.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading rg.."
        return 8
    fi

    tar xf "${__rayrc_data_dir}/rg.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:rg:'

    cp -f "${__rayrc_data_dir}/rg/rg" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/rg"*
}

__rayrc_install
unset -f __rayrc_install
