#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "denisidoro/navi" "${__rayrc_data_dir}/navi.tar.gz" \
                "aarch64" "linux" "gnu"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "denisidoro/navi" "${__rayrc_data_dir}/navi.tar.gz" \
                "x86_64" "linux" "musl"
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

    tar xf "${__rayrc_data_dir}/navi.tar.gz" -C "${__rayrc_data_dir}"

    cp -f "${__rayrc_data_dir}/navi" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/navi"*
}

__rayrc_install
unset -f __rayrc_install
