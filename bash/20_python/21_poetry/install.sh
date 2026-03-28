#!/usr/bin/env bash

[[ -x "${PIPX_BIN_DIR}/pipx" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if ! command -v poetry >/dev/null 2>&1; then
        "${PIPX_BIN_DIR}/pipx" install poetry >/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
