#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## navi's own release lacks macOS binaries (v2.24.0 ships none), so on macOS
    ## take cargo-quickinstall's build, as for eza
    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "denisidoro/navi" "${__rayrc_data_dir}/navi.tar.gz" \
                "aarch64" "linux" "gnu"
            ;;
        linux-arm*)
            __rayrc_github_downloader \
                "denisidoro/navi" "${__rayrc_data_dir}/navi.tar.gz" \
                "armv7-unknown-linux-musleabihf"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "denisidoro/navi" "${__rayrc_data_dir}/navi.tar.gz" \
                "x86_64" "linux" "musl"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_cqi_downloader navi aarch64-apple-darwin "${__rayrc_data_dir}/navi.tar.gz"
            ;;
        macos-x86_64)
            __rayrc_cqi_downloader navi x86_64-apple-darwin "${__rayrc_data_dir}/navi.tar.gz"
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

    __rayrc_install_binary "${__rayrc_data_dir}/navi.tar.gz" navi || return 8
}

__rayrc_install
unset -f __rayrc_install
