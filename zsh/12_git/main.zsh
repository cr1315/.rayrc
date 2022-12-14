#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup

    export GITSTATUS_CACHE_DIR="${__rayrc_bin_dir}"

    if [ -f /.dockerenv ]; then
        export __rayrc_inside_docker=$'\033[1m(docker)\033[00m'
    else
        export __rayrc_inside_docker=""
    fi

    # source "${__rayrc_data_dir}/gitstatus.prompt.sh"
}

__rayrc_main
unset -f __rayrc_main
