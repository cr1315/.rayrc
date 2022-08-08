#!/usr/bin/env bash

command -v git >/dev/null 2>&1 || { return; }

__rayrc_main() {
	__rayrc_common_setup_module

	# echo "$__rayrc_main/git-prompt.sh"
	# GIT_PS1_SHOWCOLORHINTS=true
	# source "$__rayrc_main/git-prompt.sh"
	# PROMPT_COMMAND='__git_ps1 "\[\033[33m\]ray\[\033[35m\]@\h \[\033[34m\]$PWD\[\033[00m\]" "\n\\\$"'
	source "${__rayrc_data_dir}/gitstatus.prompt.sh"

	# only for places without network..
	# [[ ! -f "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" ]] && cp -fp "`which gitstatusd-linux-x86_64`" "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64"

}

__rayrc_main
unset -f __rayrc_main
