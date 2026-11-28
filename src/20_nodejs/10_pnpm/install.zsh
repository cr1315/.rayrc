#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    ## same layout as install.sh: PNPM_HOME is the data dir, and pnpm links its shims
    ## (and those of `pnpm add -g` packages) into $PNPM_HOME/bin, which main.zsh puts on PATH
    export PNPM_HOME="${__rayrc_data_dir}"

    ## migrate: older installs made $PNPM_HOME/bin a symlink to libs/bin
    if [[ -L "${PNPM_HOME}/bin" ]]; then
        rm -f "${PNPM_HOME}/bin" "${__rayrc_bin_dir}"/{pnpm,pnpx,pn,pnx}
    fi

    if [[ -x "${PNPM_HOME}/bin/pnpm" ]]; then
        return 0
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
