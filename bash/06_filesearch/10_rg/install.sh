#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        ## ripgrep ships no 32-bit x86 binaries
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "aarch64" 'linux-musl.tar.gz"'
            ;;
        linux-arm*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "armv7" 'linux-musleabihf.tar.gz"'
            ;;
        linux-x86_64)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "x86_64" 'musl.tar.gz"'
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "aarch64" 'apple-darwin.tar.gz"'
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "x86_64" 'apple-darwin.tar.gz"'
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

    tar xf "${__rayrc_data_dir}/rg.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:rg:'

    cp -f "${__rayrc_data_dir}/rg/rg" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/rg"*
}

__rayrc_install
unset -f __rayrc_install
