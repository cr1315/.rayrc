#!/usr/bin/env zsh

[[ -n "$HASS_TOKEN" ]] || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    source "${__rayrc_ctl_dir}/functions.zsh"
}

__rayrc_main
unset -f __rayrc_main
