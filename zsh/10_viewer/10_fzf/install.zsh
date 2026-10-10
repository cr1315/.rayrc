#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-$(uname -m)" in
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

    ## the tarball holds only the fzf binary at its top level.
    ## extract into fzf-release/: hosts installed by the old git clone method
    ## still have a fzf/ directory here, which the cleanup below removes.
    mkdir -p "${__rayrc_data_dir}/fzf-release"
    tar xf "${__rayrc_data_dir}/fzf.tar.gz" -C "${__rayrc_data_dir}/fzf-release" fzf

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/fzf-release/fzf" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/fzf"*

    ## key bindings & completion: generate once here instead of running
    ## `source <(fzf --zsh)` on every shell startup; main.zsh sources it
    if ! "${__rayrc_bin_dir}/fzf" --zsh >"${__rayrc_ctl_dir}/shell/fzf.zsh"; then
        rm -f "${__rayrc_ctl_dir}/shell/fzf.zsh"
        __rayrc_log_warn "failed to generate shell integration for ${__rayrc_package:3}"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
