#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "linux" "arm64"
            ;;
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "linux" "arm"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "linux" "amd64"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "linux" "386"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "darwin" "arm"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "darwin" "amd64"
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

    ## install to my bin dir
    tar xf "${__rayrc_data_dir}/lf.tar.gz" -C "${__rayrc_data_dir}"
    cp -f "${__rayrc_data_dir}/lf" "${__rayrc_bin_dir}"

    ## clean
    rm -rf "${__rayrc_data_dir}/lf"*

    ## preapre for lfrc
    if [[ ! -d "${HOME}/.cache/lf" ]]; then
        mkdir -p "${HOME}/.cache/lf"
    fi
    cp -f "${__rayrc_data_dir}/config/lf/"*preview* "${__rayrc_bin_dir}"

}

__rayrc_install
unset -f __rayrc_install
