#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "$__rayrc_facts_os_type" == "linux" ]]; then
        # determine distribution name from
        #   - `uname -a`
        #   - `cat /etc/os-relase`
        # set the corresponding package-manager to __rayrc_package_manager

    elif [[ "$__rayrc_facts_os_type" == "macos" ]]; then
        # install brew for macos is not installed
        if ! command -v brew >&/dev/null; then
            $(which bash) -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        __rayrc_package_manager="brew"
    else
        echo ".rayrc: not supported OS by now.."
        return 8
    fi

    # we need git A.S.A.P.
    if ! command -v git >&/dev/null; then
        ${__rayrc_package_manager} install -y git
    fi
}

__rayrc_install ${0:A:h}
unset -f __rayrc_install
