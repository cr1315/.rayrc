#!/usr/bin/env zsh

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

alias cls="clear"
alias pd="pushd"
alias ds="dirs -v"
alias view="vim -R"
alias vi="vim"

alias ip="ip -c=auto"
