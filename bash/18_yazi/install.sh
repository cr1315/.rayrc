#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## release assets are zip only
    if ! command -v unzip >&/dev/null; then
        __rayrc_log_warn "unzip is required to install ${__rayrc_package:3}"
        return 8
    fi

    ## musl builds are static, so they run regardless of the host's glibc.
    ## "zip" filter drops the .deb of the same target.
    case "${__rayrc_facts_os_type}-`uname -m`" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "sxyazi/yazi" "${__rayrc_data_dir}/yazi.zip" \
                "aarch64" "linux-musl" "zip"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "sxyazi/yazi" "${__rayrc_data_dir}/yazi.zip" \
                "x86_64" "linux-musl" "zip"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "sxyazi/yazi" "${__rayrc_data_dir}/yazi.zip" \
                "aarch64" "apple-darwin"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "sxyazi/yazi" "${__rayrc_data_dir}/yazi.zip" \
                "x86_64" "apple-darwin"
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

    ## zip has a per-target top dir; -j flattens it so only the files we need
    ## land directly in the destination.
    ## yazi: the TUI itself / ya: plugin & flavor manager (`ya pkg`)
    mkdir -p "${__rayrc_data_dir}/yazi"
    unzip -qjo "${__rayrc_data_dir}/yazi.zip" '*/yazi' '*/ya' -d "${__rayrc_data_dir}/yazi"

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/yazi/yazi" "${__rayrc_data_dir}/yazi/ya" "${__rayrc_bin_dir}"

    ## neither binary can generate completions at runtime, so keep the bundled
    ## ones next to main.sh (sourced on every shell startup, like main.sh)
    mkdir -p "${__rayrc_ctl_dir}/completions"
    unzip -qjo "${__rayrc_data_dir}/yazi.zip" \
        '*/completions/yazi.bash' '*/completions/ya.bash' \
        -d "${__rayrc_ctl_dir}/completions"

    rm -rf "${__rayrc_data_dir}/yazi"*
}

__rayrc_install
unset -f __rayrc_install
