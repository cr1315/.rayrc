#!/usr/bin/env zsh

__rayrc_fzf_setup() {
	local __rayrc_fzf_setup_dir=$1
    # echo "\$__rayrc_fzf_setup_dir: $__rayrc_fzf_setup_dir"

    # setup fzf
    if [[ ! "$PATH" == *"$__rayrc_fzf_setup_dir/fzf/bin"* ]]; then
      export PATH="${PATH:+${PATH}:}$__rayrc_fzf_setup_dir/fzf/bin"
    fi
    # Auto-completion & Key bindings
    [[ $- == *i* ]] && source "$__rayrc_fzf_setup_dir/fzf/shell/completion.zsh" 2> /dev/null
    source "$__rayrc_fzf_setup_dir/fzf/shell/key-bindings.zsh"

	  # set env variables for fzf
    export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'
    export FZF_DEFAULT_OPTS='--layout=reverse --height 70% --border' 

    export FZF_CTRL_T_COMMAND='fd --type f --color always --hidden --follow --exclude .git'
    export FZF_CTRL_T_OPTS="--ansi --layout=reverse --height 70% --border --margin 0,0 --preview-window 'right:60%' --preview 'bat --color=always --style=numbers,grid --line-range :200 {}'"

    # export FZF_ALT_C_COMMAND=''
    # export FZF_ALT_C_OPTS=''

    # export FZF_CTRL_R_OPTS=''
}

__rayrc_fzf_setup ${0:A:h}
unset -f __rayrc_fzf_setup
