#!/usr/bin/env bash

[[ -x "${PIPX_BIN_DIR}/pipx" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if ! command -v glances >/dev/null 2>&1; then
        if [[ "${__rayrc_package_manager}" == "apk" ]]; then
            {
                apk add --no-cache --virtual .build-deps build-base python3-dev libffi-dev \
                && "${PIPX_BIN_DIR}/pipx" install glances \
                && apk del .build-deps
            } >/dev/null
        else
            "${PIPX_BIN_DIR}/pipx" install glances >/dev/null
        fi
    fi
}

__rayrc_install
unset -f __rayrc_install
