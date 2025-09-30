#!/usr/bin/env bash

[[ -n "$HASS_TOKEN" ]] >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    source "${__rayrc_ctl_dir}/functions.sh"
}

__rayrc_main
unset -f __rayrc_main
