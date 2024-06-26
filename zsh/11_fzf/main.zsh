#!/usr/bin/env zsh

# should come before git and vim
command -v fzf >/dev/null 2>&1 || { return 8; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## setup fzf
    # if [[ ! "$PATH" == *"${__rayrc_data_dir}/fzf/bin"* ]]; then
    # 	export PATH="${PATH:+${PATH}:}${__rayrc_data_dir}/fzf/bin"
    # fi

    # Auto-completion & Key bindings
    [[ $- == *i* ]] && source "${__rayrc_data_dir}/fzf/shell/completion.zsh" 2>/dev/null
    source "${__rayrc_data_dir}/fzf/shell/key-bindings.zsh"

    # set env variables for fzf
    export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'
    export FZF_DEFAULT_OPTS='--layout=reverse --height 70% --border'
    export FZF_DEFAULT_OPTS="--ansi --height 70% --border --preview-window 'right:60%' --layout reverse --margin=1,4 --preview 'bat --color=always --style=header,grid --line-range :200 {}'"
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
    --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'

    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

    export FZF_CTRL_T_COMMAND='fd --type f --color always --hidden --follow --exclude .git'
    export FZF_CTRL_T_OPTS="--ansi --layout=reverse --height 70% --border --margin 0,0 --preview-window 'right:60%' --preview 'bat --color=always --style=numbers,grid --line-range :200 {}'"

    # export FZF_ALT_C_COMMAND=''
    # export FZF_ALT_C_OPTS=''

    # export FZF_CTRL_R_OPTS=''

    source "${__rayrc_ctl_dir}/functions.sh"
}

__rayrc_main
unset -f __rayrc_main
