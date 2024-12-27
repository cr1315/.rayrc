#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "dundee/gdu" "${__rayrc_data_dir}/gdu.tar.gz" \
                "arm64.tgz" "linux"
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
            echo ".rayrc: could not retrieve binary for ${__rayrc_package:3}.."
            return 8
            ;;
    esac

    if [[ $? -ne 0 ]]; then
        echo "  .rayrc: failed to setup ${__rayrc_package:3}"
        return 8
    fi

    tar xf "${__rayrc_data_dir}/gdu.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:gdu:'

    cp -f "${__rayrc_data_dir}/gdu" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/gdu"*
}

__rayrc_install
unset -f __rayrc_install
