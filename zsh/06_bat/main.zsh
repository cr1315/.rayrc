#!/usr/bin/env zsh
command -v bat >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    # set env variables for brew? fzf? rg? fd? bat? ranger?
    export BAT_CONFIG_PATH="${__rayrc_data_dir}/config/bat.conf"

    # use bat as MANPAGER
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"

    # set aliases
    alias bat="bat --color always"
    alias cat="bat"

}

__rayrc_main
unset -f __rayrc_main
