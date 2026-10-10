#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## eza ships no macOS / 32-bit x86 binaries (use brew on macOS)
    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "aarch64" "gnu\.tar\.gz"
            ;;
        linux-arm*)
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "arm-unknown" "gnueabihf\.tar\.gz"
            ;;
        linux-x86_64)
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "musl" "x86_64" "tar.gz"
            ;;
        *)
            __rayrc_log_warn "could not retrieve binary for ${__rayrc_package:3}.."
            return 8
            ;;
    esac

    if [[ $? -ne 0 ]]; then
        __rayrc_log_warn "failed to setup ${__rayrc_package:3}"
        return 8
    fi

    tar xf "${__rayrc_data_dir}/eza.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:eza:'

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/eza/eza" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/eza"*
}

__rayrc_install
unset -f __rayrc_install
