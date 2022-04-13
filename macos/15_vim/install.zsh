#!/usr/bin/env zsh

# shortcut


__rayrc_vim_install() {
    local __rayrc_vim_install_dir=$1
    echo "\$__rayrc_vim_install_dir: $__rayrc_vim_install_dir"

    ### download plug.vim
    curl -fLo "$__rayrc_vim_install_dir/vimfiles/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    ### ln vimfiles to ~/.vim
    # mkdir ./rayrc_backup; [[ -f ~/.vimrc ]] && cp -fp ~/.vimrc ./rayrc_backup
    # determine & ln -snF
    ln -snF "$__rayrc_vim_install_dir/vimfiles" ~/.vim


    # vim -u "$__rayrc_vim_install_dir/vimfiles/plugins.vim" +PlugInstall +qa &> /dev/null
    vim -u "$__rayrc_vim_install_dir/vimfiles/plugins.vim" +PlugInstall +qa
    echo "###### after PlugInstall #####"
    pwd
    ls -ahl "$__rayrc_vim_install_dir/vimfiles"
    ls -ahl "$__rayrc_vim_install_dir/vimfiles/plugged"

}

__rayrc_vim_install ${0:A:h}
unset -f __rayrc_vim_install
