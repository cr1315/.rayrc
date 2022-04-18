#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 || { return; }

__rayrc_main_docker() {
    local __rayrc_main_docker_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

    alias d="docker"
    alias dp="docker-compose"
    alias dm="docker-machine"
}

__rayrc_main_docker
unset -f __rayrc_main_docker
