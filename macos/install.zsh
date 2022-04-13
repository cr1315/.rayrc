#!/usr/bin/env zsh

# 
# install brew first
#   __rayrc_macos_install_or_update() {}
#       use the install shell script
#           still need curl?
#           built-in wget/curl?
#
# install oh-my-zsh
#   powerlevel10k theme
#       install and configure
#
### base command
# install git, curl, wget, etc..
#
### useful utilities
# install fzf, ag/rg, fd, bat, etc..
#
### file manager
# install ranger/lf, vim plugin, etc..
#   of course, install and configure
#
# well, that's it, right? Not that difficult, right?!
#
#
#
#

__rayrc_macos_install() {
    local __rayrc_macos_install_dir=$1
    echo "\$__rayrc_macos_install_dir: $__rayrc_macos_install_dir"

    # prepend absolute(./00_bin) to $PATH
    if [[ ! "$PATH" == *"${__rayrc_macos_install_dir}"/00_bin* ]]; then
        export PATH="${__rayrc_macos_install_dir}/00_bin${PATH:+:${PATH}}"
    fi

    ### auto setup
    for dir in `ls -1 "${__rayrc_macos_install_dir}"`; do
        # echo "\$__rayrc_macos_install_dir/\$dir: $__rayrc_macos_install_dir/$dir"
        if [[ -d "$__rayrc_macos_install_dir/$dir" && -f "$__rayrc_macos_install_dir/$dir/install.zsh" && ! -f "$__rayrc_macos_install_dir/$dir/disabled" ]]; then
            echo "\$__rayrc_macos_install_dir/\$dir: $__rayrc_macos_install_dir/$dir"
            source "$__rayrc_macos_install_dir/$dir/install.zsh"
        fi
    done
}

__rayrc_macos_install ${0:A:h}
unset -f __rayrc_macos_install
