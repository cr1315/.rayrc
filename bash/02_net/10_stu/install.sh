#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "lusingander/stu" "${__rayrc_data_dir}/stu.tar.gz" \
                "aarch64" "linux-musl"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "lusingander/stu" "${__rayrc_data_dir}/stu.tar.gz" \
                "x86_64" "linux-musl"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "lusingander/stu" "${__rayrc_data_dir}/stu.tar.gz" \
                "aarch64" "darwin"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "lusingander/stu" "${__rayrc_data_dir}/stu.tar.gz" \
                "x86_64" "darwin"
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

    ## tarball is flat (only `stu` at the top level)
    tar xf "${__rayrc_data_dir}/stu.tar.gz" -C "${__rayrc_data_dir}"

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/stu" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/stu"*
}

__rayrc_install
unset -f __rayrc_install
