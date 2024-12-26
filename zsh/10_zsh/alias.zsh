#!/usr/bin/env zsh

# aliases
if command -v eza >/dev/null 2>&1; then
    # alias ls="eza --icons"
    # alias ll="eza -lg --icons"
    # alias la="eza -ahlg --icons"
    alias la="eza -ahl --icons"
    alias ll="eza -hl --icons"
    alias lt="eza -hlT --icons"
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
