#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    ## eza ships no macOS binaries (use brew there)
    case "${__rayrc_facts_os_type}-$(uname -m)" in
        linux-arm* | linux-aarch*)
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "aarch64" "linux" "tar.gz"
            ;;
        linux-*86* | linux-*ia64*)
            __rayrc_github_downloader \
                "eza-community/eza" "${__rayrc_data_dir}/eza.tar.gz" \
                "musl" "x86_64" "tar.gz"
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

    ## the tarball holds only ./eza at its top level
    tar xf "${__rayrc_data_dir}/eza.tar.gz" -C "${__rayrc_data_dir}"

    ## this will cause idempotent upgrade
    cp -f "${__rayrc_data_dir}/eza" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/eza"*
}

__rayrc_install
unset -f __rayrc_install
