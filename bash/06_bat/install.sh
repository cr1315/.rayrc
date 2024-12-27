#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "arm" "musl"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "musl" "x86_64"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "musl" "i686"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "darwin" "x86"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
                "darwin" "arm"
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

    tar xf "${__rayrc_data_dir}/bat.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:bat:'

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/bat/bat" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/bat"*
}

__rayrc_install
unset -f __rayrc_install
