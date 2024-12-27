#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "linux" "arm64"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "linux64"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "linux" "i386"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "macos" "arm64"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "stedolan/jq" "${__rayrc_data_dir}/jq" \
                "osx"
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

    if [[ -f "${__rayrc_data_dir}/jq" ]]; then
        mv -f "${__rayrc_data_dir}/jq" "${__rayrc_bin_dir}"
        chmod -R 755 "${__rayrc_bin_dir}"
        rm -rf "${__rayrc_data_dir}/jq"*
    fi
}

__rayrc_install
unset -f __rayrc_install
