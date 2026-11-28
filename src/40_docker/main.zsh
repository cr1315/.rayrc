#!/usr/bin/env zsh

## Docker Desktop is not used. Prefer a real docker CLI (e.g. colima, a remote engine);
## otherwise fall back to Apple's `container` (installed by hand, not by rayrc).
## Note: `container` is not docker-CLI compatible (no `docker compose`, different subcommands).
if command -v docker >/dev/null 2>&1; then
    __rayrc_main() {
        __rayrc_module_common_setup

        alias d="docker"
        if docker compose version &>/dev/null; then
            alias dp="docker compose"
        elif command -v docker-compose &>/dev/null; then
            alias dp="docker-compose"
        fi
        alias dm="docker-machine"
    }
elif command -v container >/dev/null 2>&1; then
    __rayrc_main() {
        __rayrc_module_common_setup

        alias docker="container"
        alias d="container"
    }
else
    return
fi

__rayrc_main
unset -f __rayrc_main
