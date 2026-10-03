#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "dandavison/delta" "${__rayrc_data_dir}/delta.tar.gz" \
                "aarch64" "linux"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "dandavison/delta" "${__rayrc_data_dir}/delta.tar.gz" \
                "x86_64" "linux-musl"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "dandavison/delta" "${__rayrc_data_dir}/delta.tar.gz" \
                "i686" "linux"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "dandavison/delta" "${__rayrc_data_dir}/delta.tar.gz" \
                "aarch64" "darwin"
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

    tar xf "${__rayrc_data_dir}/delta.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:delta:'

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/delta/delta" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/delta"*

    # git aliases
    # if git config --global --list 2>&1 | grep 'pull.rebase=' >/dev/null 2>&1; then
    #     true
    # else
    #     git config --global core.pager delta
    #     git config --global interactive.diffFilter 'delta --color-only'
    #     git config --global delta.navigate true
    #     git config --global delta.dark true
    #     git config --global merge.conflictStyle zdiff3
    # fi
}

__rayrc_install
unset -f __rayrc_install
