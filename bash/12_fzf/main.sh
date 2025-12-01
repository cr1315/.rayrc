#!/usr/bin/env bash

# should come before git and vim
command -v fzf >/dev/null 2>&1 || { return 8; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## setup fzf
    # if ! command -v fzf >&/dev/null; then
    # 	if [[ ! "$PATH" == *"${__rayrc_data_dir}/fzf/bin"* ]]; then
    # 		export PATH="${PATH:+${PATH}:}${__rayrc_data_dir}/fzf/bin"
    # 	fi
    # fi

    # Auto-completion & Key bindings
    [[ $- == *i* ]] && source "${__rayrc_data_dir}/fzf/shell/completion.bash" 2>/dev/null
    source "${__rayrc_data_dir}/fzf/shell/key-bindings.bash"

    export FZF_CTRL_R_OPTS="--preview 'echo {2..} | shfmt | bat --color=always --wrap=never --theme Dracula -p -P -l sh' --preview-window down:40%:wrap --tabstop=1 --bind 'ctrl-/:toggle-preview'"

    ## default options for fzf
    # export FZF_DEFAULT_OPTS='--height 70% --layout=reverse --border'
    export FZF_DEFAULT_OPTS="--ansi --height 80% --border --preview-window 'right:60%' --layout reverse --margin=1,4 --preview 'bat --color=always --style=header,grid --line-range :200 {}'"
    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
    --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'


    # set env variables for fzf
    export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'


    ## CTRL+T to list files
    export FZF_CTRL_T_COMMAND='fd --type f --color always --hidden --follow --exclude .git'
    export FZF_CTRL_T_OPTS="--ansi --layout=reverse --height 70% --border --margin 0,0 --preview-window 'right:60%' --preview 'bat --color=always --style=numbers,grid --line-range :200 {}'"


    ## ALT+C to quick change directory
    # export FZF_ALT_C_COMMAND=''
    export FZF_ALT_C_OPTS='--no-preview'


    ## fzf（およびそのラッパースクリプトである fzf-tmux）は非常に賢く設計されており、「tmuxの中にいるか、いないか」を自動で判別して挙動を切り替えてくれます。
    export FZF_TMUX=1
    export FZF_TMUX_OPTS="-p 90%"

    source "${__rayrc_ctl_dir}/functions.sh"
}

__rayrc_main
unset -f __rayrc_main
