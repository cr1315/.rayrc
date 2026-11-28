#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "junegunn/fzf" "${__rayrc_data_dir}/fzf.tar.gz" \
                "linux_arm64"
            ;;
        linux-armv7*)
            __rayrc_github_downloader \
                "junegunn/fzf" "${__rayrc_data_dir}/fzf.tar.gz" \
                "linux_armv7"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "junegunn/fzf" "${__rayrc_data_dir}/fzf.tar.gz" \
                "linux_amd64"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "junegunn/fzf" "${__rayrc_data_dir}/fzf.tar.gz" \
                "darwin_arm64"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "junegunn/fzf" "${__rayrc_data_dir}/fzf.tar.gz" \
                "darwin_amd64"
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

    __rayrc_install_binary "${__rayrc_data_dir}/fzf.tar.gz" fzf || return 8

    ## leftovers: fzf/ from the old git clone method, fzf-release/ from the old extraction
    rm -rf "${__rayrc_data_dir}/fzf" "${__rayrc_data_dir}/fzf-release"

    ## key bindings & completion: generate once here instead of running
    ## `eval "$(fzf --bash)"` on every shell startup; main.sh sources it.
    ## generated file -> data plane (the control plane holds tracked files only)
    mkdir -p "${__rayrc_data_dir}/shell"
    if ! "${__rayrc_bin_dir}/fzf" --bash >"${__rayrc_data_dir}/shell/fzf.bash"; then
        rm -f "${__rayrc_data_dir}/shell/fzf.bash"
        __rayrc_log_warn "failed to generate shell integration for ${__rayrc_package:3}"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
