#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    case "${__rayrc_facts_os_type}-$(uname -m)" in
        linux-arm*64* | linux-aarch*64*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "aarch64" "musl"
            ;;
        linux-arm*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "arm-unknown" "musleabihf"
            ;;
        linux-*64*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "musl" "x86_64"
            ;;
        linux-*86*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "musl" "i686" "tar.gz"
            ;;
        macos-arm* | macos-aarch*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "apple-darwin" "aarch64"
            ;;
        macos-*86* | macos-*ia64*)
            __rayrc_github_downloader \
                "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
                "apple-darwin" "x86_64"
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
    mkdir -p "${__rayrc_data_dir}/fd"
    tar xf "${__rayrc_data_dir}/fd.tar.gz" -C "${__rayrc_data_dir}/fd" --strip-components 1

    cp -f "${__rayrc_data_dir}/fd/fd" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/fd"*
}

__rayrc_install
unset -f __rayrc_install
