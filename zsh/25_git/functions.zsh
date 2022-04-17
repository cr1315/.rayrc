#!/usr/bin/env zsh

# git statusで対象となるファイルのgit diffみながらファイルを選択する
function select_file_from_git_status() {
  git status -u --short | \
    fzf -m --ansi --reverse --preview 'f() {
      local original=$@
      set -- $(echo "$@");
      if [ $(echo $original | grep -E "^M" | wc -l) -eq 1 ]; then # staged
        git diff --color --cached $2
      elif [ $(echo $original | grep -E "^\?\?" | wc -l) -eq 0 ]; then # unstaged
        git diff --color $2
      elif [ -d $2 ]; then # directory
        ls -la $2
      else
        git diff --color --no-index /dev/null $2 # untracked
      fi
    }; f {}' |\
    awk -F ' ' '{print $NF}' |
    tr '\n' ' '
}

# ↑の関数で選んだファイルを入力バッファに入れる
function insert_selected_git_files(){
    LBUFFER+=$(select_file_from_git_status)
    CURSOR=$#LBUFFER
    zle reset-prompt
}
zle -N insert_selected_git_files
bindkey "^g^s" insert_selected_git_files

# ↑の関数で選んだファイルをgit addする
function select_git_add() {
    local selected_file_to_add="$(select_file_from_git_status)"
    if [ -n "$selected_file_to_add" ]; then
      BUFFER="git add $(echo "$selected_file_to_add" | tr '\n' ' ')"
      CURSOR=$#BUFFER
    fi
    zle accept-line
}
zle -N select_git_add
bindkey "^g^a" select_git_add

# git branchとgit tagの結果からgit logを見ながらbranch/tagを選択する
function select_from_git_branch() {
  local list=$(\
    git branch --sort=refname --sort=-authordate --color --all \
      --format='%(color:red)%(authordate:short)%(color:reset) %(objectname:short) %(color:green)%(refname:short)%(color:reset) %(if)%(HEAD)%(then)* %(else)%(end)'; \
    git tag --color -l \
      --format='%(color:red)%(creatordate:short)%(color:reset) %(objectname:short) %(color:yellow)%(align:width=45,position=left)%(refname:short)%(color:reset)%(end)')

  echo $list | fzf --preview 'f() {
      set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}");
      [ $# -eq 0 ] || git --no-pager log --oneline -100 --pretty=format:"%C(red)%ad%Creset %C(green)%h%Creset %C(blue)%<(15,trunc)%an%Creset: %s" --date=short --color $1;
    }; f {}' |\
    sed -e 's/\* //g' | \
    awk '{print $3}'  | \
    sed -e "s;remotes/;;g" | \
    perl -pe 's/\n/ /g'
}

# ↑の関数で選んだbranch/tagを入力バッファに入れる
function select_to_insert_branch() {
    LBUFFER+=$(select_from_git_branch)
    CURSOR=$#LBUFFER
    zle reset-prompt
}
zle -N select_to_insert_branch
bindkey "^g^o" select_to_insert_branch

# ↑の関数で選んだbranch/tagにgit checkoutする
function select_git_checkout() {
    local selected_file_to_checkout=`select_from_git_branch | sed -e "s;origin/;;g"`
    if [ -n "$selected_file_to_checkout" ]; then
      BUFFER="git checkout $(echo "$selected_file_to_checkout" | tr '\n' ' ')"
      CURSOR=$#BUFFER
    fi
    zle accept-line
}
zle -N select_git_checkout
bindkey "^gco" select_git_checkout