#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "arm" 'linux-musleabihf.tar.gz"'
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "x86_64" 'musl.tar.gz"'
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "86" 'linux-gnu.tar.gz"'
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "linux" "aarch"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_data_dir}/rg.tar.gz" \
                "darwin" "x86"
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

    tar xf "${__rayrc_data_dir}/rg.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:rg:'

    cp -f "${__rayrc_data_dir}/rg/rg" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/rg"*
}

__rayrc_install
unset -f __rayrc_install
