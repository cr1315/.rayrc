#!/usr/bin/env zsh

######################################################################
#
# Logging
#
######################################################################
## depth = __rayrc_source_facade のネスト数（zsh では $funcstack から数える）
__rayrc_log_info() {
    local -a facades
    facades=("${(@M)funcstack:#__rayrc_source_facade}")
    printf '%*s.rayrc: %s\n' $(( ${#facades} * 2 )) '' "$1"
}

__rayrc_log_warn() {
    local -a facades
    facades=("${(@M)funcstack:#__rayrc_source_facade}")
    printf '%*s.rayrc: \033[33m%s\033[0m\n' $(( ${#facades} * 2 )) '' "$1"
}
