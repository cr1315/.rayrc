#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_common_setup_module

    alias d="docker"
    alias dp="docker-compose"
    alias dm="docker-machine"
}

__rayrc_main
unset -f __rayrc_main
