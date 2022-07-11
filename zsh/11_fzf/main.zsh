#!/usr/bin/env zsh

__rayrc_main_fzf() {
  local __rayrc_dir_ctl_fzf
  local __rayrc_dir_data_fzf

  __rayrc_dir_ctl_fzf=$1
  # echo "\${__rayrc_dir_ctl_fzf}: ${__rayrc_dir_ctl_fzf}"

  __rayrc_dir_data_fzf="${__rayrc_dir_libs}/${package:3}"
  # echo "\${__rayrc_dir_data_fzf}: ${__rayrc_dir_data_fzf}"

  # setup fzf
  if [[ ! "$PATH" == *"${__rayrc_dir_data_fzf}/fzf/bin"* ]]; then
    export PATH="${PATH:+${PATH}:}${__rayrc_dir_data_fzf}/fzf/bin"
  fi
  # Auto-completion & Key bindings
  [[ $- == *i* ]] && source "${__rayrc_dir_data_fzf}/fzf/shell/completion.zsh" 2>/dev/null
  source "${__rayrc_dir_data_fzf}/fzf/shell/key-bindings.zsh"

  # set env variables for fzf
  export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'
  export FZF_DEFAULT_OPTS='--layout=reverse --height 70% --border'

  export FZF_CTRL_T_COMMAND='fd --type f --color always --hidden --follow --exclude .git'
  export FZF_CTRL_T_OPTS="--ansi --layout=reverse --height 70% --border --margin 0,0 --preview-window 'right:60%' --preview 'bat --color=always --style=numbers,grid --line-range :200 {}'"

  # export FZF_ALT_C_COMMAND=''
  # export FZF_ALT_C_OPTS=''

  # export FZF_CTRL_R_OPTS=''
}

__rayrc_main_fzf ${0:A:h}
unset -f __rayrc_main_fzf
