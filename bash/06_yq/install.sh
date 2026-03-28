#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'linux_arm64"'
            ;;
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'linux_arm"'
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'linux_amd64"'
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'linux_386"'
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'darwin_arm64"'
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'darwin_amd64"'
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

    mv -f "${__rayrc_data_dir}/yq" "${__rayrc_bin_dir}"
    chmod -R 755 "${__rayrc_bin_dir}"
    rm -rf "${__rayrc_data_dir}/yq"*
}

__rayrc_install
unset -f __rayrc_install
