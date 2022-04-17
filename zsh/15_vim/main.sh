#!/usr/bin/env zsh

__rayrc_vim_setup() {

	# in zsh, ${0:A:p} -> full dir path?
	# mydir=${0:a:h}
	# SCRIPT_PATH="${0:A:h}"


	local current_dir=${0:A:h}
	echo "current_dir: ${current_dir}"








	# set PATH

	# set env variables for brew? fzf? rg? fd? bat? ranger?

	# set env for zsh-completion


	# make .rayrc an oh-my-zsh plugin??
	# that would be so cool, right?
	# TODO: don't know why, but after run cmpinit, no effect







}


__rayrc_vim_setup
unset -f __rayrc_vim_setup
