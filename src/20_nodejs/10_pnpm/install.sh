#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## pnpm installs itself as a global package under PNPM_HOME
    ## (global/, store/) and links its shims into $PNPM_HOME/bin — a fixed
    ## location that cannot be configured separately.
    export PNPM_HOME="${__rayrc_data_dir}"

    if [[ -x "${__rayrc_bin_dir}/pnpm" ]]; then
        return 0
    fi

    ## Make $PNPM_HOME/bin a symlink to libs/bin so that pnpm's own shims and
    ## the bins of `pnpm add -g` packages land flat in libs/bin. The shims
    ## resolve symlinks and reach global/ relative to their real directory.
    ## Relative link: libs/nodejs/pnpm/bin -> libs/bin
    if [[ ! -e "${PNPM_HOME}/bin" ]]; then
        ln -s ../../bin "${PNPM_HOME}/bin"
    elif [[ ! -L "${PNPM_HOME}/bin" ]]; then
        __rayrc_log_warn "${PNPM_HOME}/bin exists and is not a symlink to libs/bin"
        return 8
    fi

    ## Official installer auto-detects OS/arch (incl. musl vs glibc) and
    ## verifies the npm registry signature. PNPM_NO_MODIFY_PATH stops
    ## `pnpm setup` from editing shell rc files — rayrc owns PATH.
    if ! (
        set -o pipefail
        curl -fsSL https://get.pnpm.io/install.sh \
            | env PNPM_HOME="${PNPM_HOME}" PNPM_NO_MODIFY_PATH=1 sh
    ) >&/dev/null; then
        __rayrc_log_warn "failed to install pnpm"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
