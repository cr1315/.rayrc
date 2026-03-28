#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "mvdan/sh" "${__rayrc_data_dir}/shfmt" \
                "linux" "arm64"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "mvdan/sh" "${__rayrc_data_dir}/shfmt" \
                "linux" "amd64"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "mvdan/sh" "${__rayrc_data_dir}/shfmt" \
                "linux" "386"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "mvdan/sh" "${__rayrc_data_dir}/shfmt" \
                "darwin" "amd64"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "mvdan/sh" "${__rayrc_data_dir}/shfmt" \
                "darwin" "arm64"
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

    ## this will cause idempotent upgrade
    chmod +x "${__rayrc_data_dir}/shfmt"
    cp -f "${__rayrc_data_dir}/shfmt" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/shfmt"*
}

__rayrc_install
unset -f __rayrc_install
