#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "arm64.tgz" "linux"
            ;;
        linux-arm*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "linux_arm\.tgz"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "amd64.tgz" "linux"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "386.tgz" "linux"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "darwin" "arm64.tgz"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "darwin" "amd64.tgz"
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

    ## the tarball holds a single binary named gdu_<os>_<arch>; it is renamed to gdu
    __rayrc_install_binary "${__rayrc_data_dir}/gdu.tar.gz" 'gdu_*=gdu' || return 8
}

__rayrc_install
unset -f __rayrc_install
