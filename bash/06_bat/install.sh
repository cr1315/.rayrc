#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "arm" "musl"
        elif uname -m | grep -E -q "64" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "musl" "x86_64"
        elif uname -m | grep -E -q "86" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "musl" "i686"
        else
            echo ".rayrc: unsupported cpu architecture for downloading rg.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "darwin" "x86"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "darwin" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading rg.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading rg.."
        return 8
    fi

    if [[ $? -ne 0 ]]; then
        echo "  .rayrc: failed to setup ${__rayrc_package:3}"
        return 8
    fi

    tar xf "${__rayrc_data_dir}/bat.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:bat:'

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/bat/bat" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/bat"*
}

__rayrc_install
unset -f __rayrc_install
