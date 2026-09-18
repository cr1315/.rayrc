#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## Keep atuin fully self-contained under libs/atuin (mirrors the uv module):
    ## - config.toml lives in libs/atuin/config
    ## - history.db / records.db / key / session etc. live in libs/atuin/data
    export ATUIN_CONFIG_DIR="${__rayrc_data_dir}/config"
    export ATUIN_DATA_DIR="${__rayrc_data_dir}/data"

    if [[ -x "${__rayrc_bin_dir}/atuin" ]]; then
        return 0
    fi

    ## Use the cargo-dist binary installer (atuin-installer.sh), NOT
    ## setup.atuin.sh — the latter rewrites ~/.bashrc/.zshrc/fish config and
    ## installs agent hooks, which collides with rayrc owning PATH and init.
    ##
    ## ATUIN_INSTALL_DIR uses a flat layout, dropping the `atuin` binary (and,
    ## since self-update stays enabled, an `atuin-update` binary) straight into
    ## libs/bin. ATUIN_NO_MODIFY_PATH stops it from editing rc files.
    if ! (
        set -o pipefail
        curl --proto '=https' --tlsv1.2 -LsSf \
            https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh \
            | env ATUIN_INSTALL_DIR="${__rayrc_bin_dir}" \
                  ATUIN_NO_MODIFY_PATH=1 \
                  sh
    ) >&/dev/null; then
        __rayrc_log_warn "failed to install atuin"
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
