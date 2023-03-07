#!/usr/bin/env bash

command -v git >/dev/null 2>&1 || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    git clone --quiet --depth 1 "https://github.com/romkatv/gitstatus.git" \
        "${__rayrc_data_dir}/gitstatus" >&/dev/null

    # git aliases
    if git config --global --list 2>&1 | grep 'alias.co=checkout' >/dev/null 2>&1; then
        true
    else
        git config --global alias.st status
        git config --global alias.co checkout
        git config --global alias.cm commit
        git config --global alias.b branch
        git config --global alias.lg1 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
        git config --global alias.lg2 "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
        git config --global alias.lg '!git lg1'
        git config --global pull.rebase false
        git config --global credential.helper store
    fi

    # echo ""
    # echo "  start updating submodules.."
    # (cd ${__rayrc_root_dir} && git submodule update --init --recursive --depth 1)
}

__rayrc_install
unset -f __rayrc_install
