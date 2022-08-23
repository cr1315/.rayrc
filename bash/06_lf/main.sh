#!/usr/bin/env bash

command -v lf >/dev/null 2>&1 || { return; }

__rayrc_main() {
	__rayrc_module_common_setup

    alias lf="XDG_CONFIG_HOME='${__rayrc_data_dir}/config' XDG_DATA_HOME='${__rayrc_data_dir}/data' lf"

}

__rayrc_main
unset -f __rayrc_main

lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$("cat" "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ]; then
            if [ "$dir" != "$(pwd)" ]; then
                cd "$dir"
            fi
        fi
    fi
}

bind '"\C-o":"lfcd\C-m"'

