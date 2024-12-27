#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "aarch64" "musl"
            ;;
        linux-*86* | linux-*ia64*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "musl" "x86_64"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "macos" "arm"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "macos" "x86"
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

    tar xf "${__rayrc_data_dir}/fd.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:fd:'

    cp -f "${__rayrc_data_dir}/fd/fd" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/fd"*
}

__rayrc_install
unset -f __rayrc_install
