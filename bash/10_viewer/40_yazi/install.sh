#!/usr/bin/env bash

## extract the files named <names...> from <zip> straight into <dest>,
## dropping the archive's per-target top dir.
## Synology's /bin/unzip is a symlink to p7zip, which rejects Info-ZIP
## switches, so 7z is driven with its own syntax there.
__rayrc_unzip_flat() {
    local zip="$1" dest="$2"
    shift 2

    mkdir -p "${dest}"
    if [[ "${__rayrc_facts_os_distribution}" == "Synology" ]]; then
        ## e: extract without directory names (= unzip -j) / -r: match names at any depth
        7z e -y -bso0 -bsp0 -o"${dest}" "${zip}" -r "$@"
    else
        unzip -qjo "${zip}" "${@/#/*/}" -d "${dest}"
    fi
}

__rayrc_install() {
    __rayrc_module_common_setup

    ## release assets are zip only
    local __rayrc_unzipper="unzip"
    [[ "${__rayrc_facts_os_distribution}" == "Synology" ]] && __rayrc_unzipper="7z"
    if ! command -v "${__rayrc_unzipper}" >&/dev/null; then
        __rayrc_log_warn "${__rayrc_unzipper} is required to install ${__rayrc_package:3}"
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

    ## yazi: the TUI itself / ya: plugin & flavor manager (`ya pkg`)
    ## cp also catches names missing from the zip (7z exits 0 on no match).
    ## this will cause idempotent upgrade
    if ! __rayrc_unzip_flat "${__rayrc_data_dir}/yazi.zip" "${__rayrc_data_dir}/yazi" yazi ya \
        || ! cp -f "${__rayrc_data_dir}/yazi/yazi" "${__rayrc_data_dir}/yazi/ya" "${__rayrc_bin_dir}"; then
        __rayrc_log_warn "failed to extract ${__rayrc_package:3}"
        rm -rf "${__rayrc_data_dir}/yazi"*
        return 8
    fi

    ## neither binary can generate completions at runtime, so keep the bundled
    ## ones next to main.sh (sourced on every shell startup, like main.sh)
    if ! __rayrc_unzip_flat "${__rayrc_data_dir}/yazi.zip" "${__rayrc_ctl_dir}/completions" \
        yazi.bash ya.bash; then
        __rayrc_log_warn "failed to extract completions for ${__rayrc_package:3}"
    fi

    rm -rf "${__rayrc_data_dir}/yazi"*
}

__rayrc_install
unset -f __rayrc_install __rayrc_unzip_flat
