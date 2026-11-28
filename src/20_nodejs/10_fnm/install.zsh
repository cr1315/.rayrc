#!/usr/bin/env zsh

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

    ## same as install.sh: --install-dir drops just `fnm` into libs/bin, --skip-shell keeps
    ## rc files untouched, --force-install downloads the binary on macOS instead of using Homebrew.
    ## Node itself is not installed here (run `fnm install`); versions land in FNM_DIR (main.zsh).
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
