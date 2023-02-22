#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    #
    # we need git, curl, etc A.S.A.P.
    if ! command -v git >&/dev/null; then
        ${__rayrc_package_manager} update &>/dev/null
        ${__rayrc_package_manager} install git &>/dev/null
    fi
    if ! command -v curl >&/dev/null; then
        ${__rayrc_package_manager} update &>/dev/null
        ${__rayrc_package_manager} install curl &>/dev/null
    fi
    if ! command -v grep >&/dev/null; then
        ${__rayrc_package_manager} update &>/dev/null
        ${__rayrc_package_manager} install grep &>/dev/null
    fi
    if ! command -v tar >&/dev/null; then
        ${__rayrc_package_manager} update &>/dev/null
        ${__rayrc_package_manager} install tar &>/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
