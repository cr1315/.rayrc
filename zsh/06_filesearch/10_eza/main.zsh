#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup

    # aliases
    if command -v eza >/dev/null 2>&1; then
        # alias ls="eza --icons"
        # alias ll="eza -lg --icons"
        # alias la="eza -ahlg --icons"
        alias la="eza --icons --git --time-style long-iso -ahl"
        alias ll="eza --icons --git --time-style long-iso -hl"
        alias lt="eza --icons --git --time-style long-iso -hlT"
    else
        alias la="ls -Ahl"
        alias ll="ls -hl"
    fi

}

__rayrc_main
unset -f __rayrc_main
