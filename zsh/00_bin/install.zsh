#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    ## OS / distribution not detected: in zsh, `${=empty} >&/dev/null` runs $NULLCMD (cat) and hangs
    if [[ -z "${__rayrc_package_manager}" ]]; then
        __rayrc_log_warn "no package manager detected, skipping ${__rayrc_package:3}.."
        return 8
    fi

    #
    # we need git, curl, etc A.S.A.P.
    if ! command -v git >&/dev/null ||
       ! command -v curl >&/dev/null ||
       ! command -v grep >&/dev/null ||
       ! command -v tar >&/dev/null; then

        ${=__rayrc_pm_update_repo} >&/dev/null
    fi
    if ! command -v git >&/dev/null; then
        ${=__rayrc_package_manager} install -y git >&/dev/null
    fi
    if ! command -v curl >&/dev/null; then
        ${=__rayrc_package_manager} install -y curl >&/dev/null
    fi
    if ! command -v grep >&/dev/null; then
        ${=__rayrc_package_manager} install -y grep >&/dev/null
    fi
    if ! command -v tar >&/dev/null; then
        ${=__rayrc_package_manager} install -y tar >&/dev/null
    fi
    if [[ "$__rayrc_package_manager" == "apk" ]]; then
        ${=__rayrc_package_manager} add tar >&/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
