#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    ## same layout as install.sh: PNPM_HOME is the data dir, and $PNPM_HOME/bin is a
    ## relative symlink to libs/bin so that pnpm's shims land flat in libs/bin
    export PNPM_HOME="${__rayrc_data_dir}"

    if [[ -x "${__rayrc_bin_dir}/pnpm" ]]; then
        return 0
    fi

    if [[ ! -e "${PNPM_HOME}/bin" ]]; then
        ln -s ../../bin "${PNPM_HOME}/bin"
    elif [[ ! -L "${PNPM_HOME}/bin" ]]; then
        __rayrc_log_warn "${PNPM_HOME}/bin exists and is not a symlink to libs/bin"
        return 8
    fi

    ## PNPM_NO_MODIFY_PATH stops `pnpm setup` from editing shell rc files — rayrc owns PATH
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
