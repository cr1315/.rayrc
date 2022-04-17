#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 || { return; }

__rayrc_docker_setup() {
    local __rayrc_docker_setup_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

    alias d="docker"
    alias dp="docker-compose"
    alias dm="docker-machine"
}

__rayrc_docker_setup
unset -f __rayrc_docker_setup
