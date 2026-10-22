#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    ## delta ships no x86_64 macOS binaries
    case "${__rayrc_facts_os_type}-$(uname -m)" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "dandavison/delta" "${__rayrc_data_dir}/delta.tar.gz" \
                "aarch64" "linux"
            ;;
        linux-arm*)
            __rayrc_github_downloader \
                "dandavison/delta" "${__rayrc_data_dir}/delta.tar.gz" \
                "arm-unknown" "gnueabihf"
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

    ## --transform is GNU tar only; --strip-components works with macOS bsdtar too
    mkdir -p "${__rayrc_data_dir}/delta"
    tar xf "${__rayrc_data_dir}/delta.tar.gz" -C "${__rayrc_data_dir}/delta" --strip-components 1

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/delta/delta" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/delta"*
}

__rayrc_install
unset -f __rayrc_install
