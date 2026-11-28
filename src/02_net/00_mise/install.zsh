#!/usr/bin/env zsh

## mise: binary only for now (same as install.sh)
__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -x "${__rayrc_bin_dir}/mise" ]]; then
        return 0
    fi

    ## official installer (checksum-verified, never edits rc files); see install.sh
    if ! (
        set -o pipefail
        curl -fsSL https://mise.run \
            | env MISE_INSTALL_PATH="${__rayrc_bin_dir}/mise" MISE_INSTALL_HELP=0 sh
    ) >&/dev/null; then
        __rayrc_log_warn "failed to install mise"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
