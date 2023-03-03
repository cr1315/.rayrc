#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    #
    # defined in ROOT/bash/install.sh as if it is global.
    # local __rayrc_bin_dir
    #
    # we need git, curl, etc A.S.A.P.
    ## TODO: bufix: yum makecache do the same thing as apt update in debian..
    if ! command -v git >&/dev/null; then
        ${__rayrc_package_manager} update -y
        ${__rayrc_package_manager} install -y git
    fi
    if ! command -v curl >&/dev/null; then
        ${__rayrc_package_manager} update -y
        ${__rayrc_package_manager} install -y curl
    fi
    if ! command -v grep >&/dev/null; then
        ${__rayrc_package_manager} update -y
        ${__rayrc_package_manager} install -y grep
    fi
    if ! command -v tar >&/dev/null; then
        ${__rayrc_package_manager} update -y
        ${__rayrc_package_manager} install -y tar
    fi
}

__rayrc_install
unset -f __rayrc_install
