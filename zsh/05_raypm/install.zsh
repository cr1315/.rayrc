#!/usr/bin/env zsh

# shortcut


__rayrc_brew_install() {
    local __rayrc_brew_install_dir=$1
    # echo "\$__rayrc_brew_install_dir: $__rayrc_brew_install_dir"

    echo "##### installing brew #####"
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "##### $(command -v brew) installed #####"
    fi

}

__rayrc_brew_install ${0:A:h}
unset -f __rayrc_brew_install
