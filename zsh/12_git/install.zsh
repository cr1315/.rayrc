#!/usr/bin/env zsh

# shortcut


__rayrc_install_git() {
    local __rayrc_dir_ctl_git
    local __rayrc_dir_data_git


    __rayrc_dir_ctl_git=$1
    # echo "\${__rayrc_dir_ctl_git}: ${__rayrc_dir_ctl_git}"

    __rayrc_dir_data_git="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_git}: ${__rayrc_dir_data_git}"
    if [[ ! -d ${__rayrc_dir_data_git} ]]; then
        mkdir -p ${__rayrc_dir_data_git}
    fi


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

    echo "##### git config --list --global #####"
    git config --list --global

}

__rayrc_install_git ${0:A:h}
unset -f __rayrc_install_git
