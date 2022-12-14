#!/usr/bin/env zsh

# aliases
if command -v exa >/dev/null 2>&1; then
    # alias ls="exa --icons"
    # alias ll="exa -lg --icons"
    # alias la="exa -ahlg --icons"
    alias la="exa -ahl --icons"
    alias ll="exa -hl --icons"
    alias lt="exa -hlT --icons"
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
