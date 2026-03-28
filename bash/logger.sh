#!/usr/bin/env bash

######################################################################
#
# Logging
#
######################################################################
__rayrc_log_info() {
    local depth=0
    local f
    for f in "${FUNCNAME[@]}"; do
        [[ "$f" == "__rayrc_source_facade" ]] && (( depth++ ))
    done
    printf '%*s.rayrc: %s\n' $(( depth * 2 )) '' "$1"
}
