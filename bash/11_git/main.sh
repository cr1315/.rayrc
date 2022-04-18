#!/usr/bin/env bash

command -v git >/dev/null 2>&1 || { return; }


__rayrc_main_git() {
    local __rayrc_dir_ctl_git
    local __rayrc_dir_data_git


    __rayrc_dir_ctl_git="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_git}: ${__rayrc_dir_ctl_git}"

    __rayrc_dir_data_git="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_git}: ${__rayrc_dir_data_git}"


	# echo "$__rayrc_main_git_dir/git-prompt.sh"
	# GIT_PS1_SHOWCOLORHINTS=true
	# source "$__rayrc_main_git_dir/git-prompt.sh"
	# PROMPT_COMMAND='__git_ps1 "\[\033[33m\]ray\[\033[35m\]@\h \[\033[34m\]$PWD\[\033[00m\]" "\n\\\$"'
	source "${__rayrc_dir_data_git}/gitstatus.prompt.sh"

	# only for places without network..
	[[ ! -f "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" ]] && cp -fp "`which gitstatusd-linux-x86_64`" "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64"

}

__rayrc_main_git
unset -f __rayrc_main_git

