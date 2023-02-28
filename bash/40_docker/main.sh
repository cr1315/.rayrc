#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    alias d="docker"
    if docker compose version &>/dev/null; then
        alias dp="docker compose"
    else
        alias dp="docker-compose"
    fi
    alias dm="docker-machine"
}

__rayrc_main
unset -f __rayrc_main
