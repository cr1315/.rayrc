#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }


__rayrc_vim_install() {
	local __rayrc_vim_install_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_vim_install_dir: ${__rayrc_vim_install_dir}"

    # we don't need a `.vimrc`
    if [[ -f "$HOME/.vimrc" ]]; then
        mv "$HOME/.vimrc" "$HOME/.rayrc_bkup.vimrc"
    fi

    ### download plug.vim
    curl -fLo "$__rayrc_vim_install_dir/vimfiles/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    ### ln vimfiles to ~/.vim
    # mkdir ./rayrc_backup; [[ -f ~/.vimrc ]] && cp -fp ~/.vimrc ./rayrc_backup
    # determine & ln -snF
    ls -ahl $HOME
    ls -ahl $HOME/.vim
    ln -snf "$__rayrc_vim_install_dir/vimfiles" ~/.vim


    # vim -u "$__rayrc_vim_install_dir/vimfiles/plugins.vim" +PlugInstall +qa &> /dev/null
    vim -u "$__rayrc_vim_install_dir/vimfiles/plugins.vim" +PlugInstall +qa
    echo "###### after PlugInstall #####"
    pwd
    ls -ahl "$__rayrc_vim_install_dir/vimfiles"
    ls -ahl "$__rayrc_vim_install_dir/vimfiles/plugged"

}

__rayrc_vim_install
unset -f __rayrc_vim_install


