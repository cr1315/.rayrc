#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "aarch64" "linux" "tar.gz"
        elif uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "musl" "x86_64" "tar.gz"
        else
            echo ".rayrc: unsupported cpu architecture for downloading eza.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "arm" "linux" "tar.gz"
        elif uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "musl" "x86_64" "tar.gz"
        else
            echo ".rayrc: unsupported cpu architecture for downloading eza.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading eza.."
        return 8
    fi

    if [[ $? -ne 0 ]]; then
        echo "  .rayrc: failed to setup ${__rayrc_package:3}"
        return 8
    fi

    tar xf "${__rayrc_data_dir}/eza.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:eza:'

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/eza/eza" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/eza"*
}

__rayrc_install
unset -f __rayrc_install
