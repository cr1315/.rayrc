#!/usr/bin/env bash

[[ -x "${PIPX_BIN_DIR}/pipx" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    ## ansible<2.10 requires Python < 3.11
    python3 -c "import sys; sys.exit(0 if sys.version_info < (3, 11) else 1)" || {
        echo "  .rayrc: skipping ansible — requires Python < 3.11 (current: $(python3 --version))"
        return
    }

    if ! command -v ansible >/dev/null 2>&1; then
        "${PIPX_BIN_DIR}/pipx" install --include-deps --system-site-packages "ansible<2.10" >/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
