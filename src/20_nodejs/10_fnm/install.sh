#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -x "${__rayrc_bin_dir}/fnm" ]]; then
        return 0
    fi

    ## the official installer unzips the release asset itself
    if ! command -v unzip >/dev/null 2>&1; then
        __rayrc_log_warn "unzip is required to install fnm"
        return 8
    fi

    ## Official installer picks the asset by OS/arch (fnm-linux is static, so
    ## musl works too). --install-dir drops just the `fnm` binary into libs/bin
    ## (flat layout); --skip-shell stops it from editing shell rc files — rayrc
    ## owns PATH. --force-install makes macOS download the binary instead of
    ## going through Homebrew; it has no effect on Linux.
    ## Node itself is not installed here: run `fnm install` manually. Versions
    ## land in FNM_DIR, which main.sh points at libs/nodejs/fnm.
    if ! (
        set -o pipefail
        curl -fsSL https://fnm.vercel.app/install \
            | bash -s -- --install-dir "${__rayrc_bin_dir}" --skip-shell --force-install
    ) >&/dev/null; then
        __rayrc_log_warn "failed to install fnm"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
