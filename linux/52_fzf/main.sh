#!/usr/bin/env bash

command -v fzf >/dev/null 2>&1 || { return; }

__rayrc_fzf_setup() {
    local __rayrc_fzf_setup_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

    source "${__rayrc_fzf_setup_dir}/.fzf/shell/completion.bash" 2> /dev/null
    source "${__rayrc_fzf_setup_dir}/.fzf/shell/key-bindings.bash"

    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

    # export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border'
    export BAT_THEME="Dracula"
    export FZF_DEFAULT_OPTS="--ansi --height 70% --preview-window 'right:60%' --layout reverse --margin=1,4 --preview 'bat --color=always --style=header,grid --line-range :200 {}'"

    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
    --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'
}

__rayrc_fzf_setup
unset -f __rayrc_fzf_setup
