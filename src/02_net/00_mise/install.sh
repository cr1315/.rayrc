#!/usr/bin/env bash

## mise: polyglot tool version manager. For now only the binary is installed
## (the shell integration — activate / shims — comes when we decide how to use it).
## It sits in 02_net only provisionally, to avoid a new top-level group.
__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -x "${__rayrc_bin_dir}/mise" ]]; then
        return 0
    fi

    ## Official installer: picks the asset by OS / arch (glibc vs musl too) and
    ## verifies its checksum. MISE_INSTALL_PATH drops just the binary into libs/bin;
    ## it never edits shell rc files, and MISE_INSTALL_HELP=0 drops the "activate"
    ## hint. Update later with `mise self-update`.
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
