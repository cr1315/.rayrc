#!/usr/bin/env bash

command -v git >/dev/null 2>&1 || { return; }


__rayrc_git_setup() {
	local __rayrc_git_setup_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_git_setup_dir: ${__rayrc_git_setup_dir}"

	# echo "$__rayrc_git_setup_dir/git-prompt.sh"
	# GIT_PS1_SHOWCOLORHINTS=true
	# source "$__rayrc_git_setup_dir/git-prompt.sh"
	# PROMPT_COMMAND='__git_ps1 "\[\033[33m\]ray\[\033[35m\]@\h \[\033[34m\]$PWD\[\033[00m\]" "\n\\\$"'
	source ${__rayrc_git_setup_dir}/gitstatus.prompt.sh

	# only for places without network..
	[[ ! -f "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" ]] && cp -fp "`which gitstatusd-linux-x86_64`" "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64"

	# git aliases
	git config --global --list | grep 'alias.co=checkout' >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		git config --global alias.st status
		git config --global alias.co checkout
		git config --global alias.cm commit
		git config --global alias.b  branch
		git config --global alias.lg1 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
		git config --global alias.lg2 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
		git config --global alias.lg '!git lg1'
	fi

}

__rayrc_git_setup
unset -f __rayrc_git_setup

