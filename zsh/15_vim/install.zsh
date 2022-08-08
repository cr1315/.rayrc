#!/usr/bin/env zsh

__rayrc_install_vim() {
    local __rayrc_dir_ctl_vim
    local __rayrc_dir_data_vim

    __rayrc_dir_ctl_vim=$1
    # echo "\${__rayrc_dir_ctl_vim}: ${__rayrc_dir_ctl_vim}"

    __rayrc_dir_data_vim="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_vim}: ${__rayrc_dir_data_vim}"

    ### download plug.vim
    curl -fLo "${__rayrc_dir_data_vim}/vimfiles/autoload/plug.vim" --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    ### ln vimfiles to ~/.vim
    # mkdir ./rayrc_backup; [[ -f ~/.vimrc ]] && cp -fp ~/.vimrc ./rayrc_backup
    # determine & ln -snF
    ln -snf "${__rayrc_dir_data_vim}/vimfiles" ~/.vim

    vim -u "${__rayrc_dir_data_vim}/vimfiles/plugins.vim" +PlugInstall +qa >&/dev/null
    # echo "###### after PlugInstall #####"
    # pwd
    # ls -ahl "${__rayrc_dir_data_vim}/vimfiles"
    # ls -ahl "${__rayrc_dir_data_vim}/vimfiles/plugged"

}

__rayrc_install_vim ${0:A:h}
unset -f __rayrc_install_vim
