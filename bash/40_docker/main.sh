#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    alias d="docker"
    alias dp="docker-compose"
    alias dm="docker-machine"
}

__rayrc_main
unset -f __rayrc_main
