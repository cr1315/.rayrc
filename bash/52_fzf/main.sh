#!/usr/bin/env bash

# should come before git and vim

__rayrc_main_fzf() {
    local __rayrc_dir_ctl_fzf
    local __rayrc_dir_data_fzf


    __rayrc_dir_ctl_fzf="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_fzf}: ${__rayrc_dir_ctl_fzf}"

    __rayrc_dir_data_fzf="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_fzf}: ${__rayrc_dir_data_fzf}"


    # setup fzf
    if ! command -v fzf >& /dev/null; then
      if [[ ! "$PATH" == *"${__rayrc_dir_data_fzf}/fzf/bin"* ]]; then
        export PATH="${PATH:+${PATH}:}${__rayrc_dir_data_fzf}/fzf/bin"
      fi
    fi

    command -v fzf >/dev/null 2>&1 || { return 8; }

    # Auto-completion & Key bindings
    [[ $- == *i* ]] && source "${__rayrc_dir_data_fzf}/fzf/shell/completion.bash" 2> /dev/null
    source "${__rayrc_dir_data_fzf}/fzf/shell/key-bindings.bash"


    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

    # export FZF_DEFAULT_OPTS='--height 70% --layout=reverse --border'
    export FZF_DEFAULT_OPTS="--ansi --height 70% --border --preview-window 'right:60%' --layout reverse --margin=1,4 --preview 'bat --color=always --style=header,grid --line-range :200 {}'"

    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
    --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'

	  # set env variables for fzf
    export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'

    export FZF_CTRL_T_COMMAND='fd --type f --color always --hidden --follow --exclude .git'
    export FZF_CTRL_T_OPTS="--ansi --layout=reverse --height 70% --border --margin 0,0 --preview-window 'right:60%' --preview 'bat --color=always --style=numbers,grid --line-range :200 {}'"

    # export FZF_ALT_C_COMMAND=''
    # export FZF_ALT_C_OPTS=''

}

__rayrc_main_fzf
unset -f __rayrc_main_fzf
