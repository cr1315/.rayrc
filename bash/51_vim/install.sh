#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }


__rayrc_install_vim() {
    local __rayrc_dir_ctl_vim
    local __rayrc_dir_data_vim


    __rayrc_dir_ctl_vim="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_vim}: ${__rayrc_dir_ctl_vim}"

    __rayrc_dir_data_vim="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_vim}: ${__rayrc_dir_data_vim}"

    if [[ ! -d "${__rayrc_dir_data_vim}/__rayrc_backup" ]]; then
        mkdir -p "${__rayrc_dir_data_vim}/__rayrc_backup"
    fi


    # backup the user's .vimrc or even .vim folder
    if [[ -f "$HOME/.vimrc" ]]; then
        mv "$HOME/.vimrc" "${__rayrc_dir_data_vim}/__rayrc_backup/.vimrc"
    fi
    if [[ -d "$HOME/.vim" && ! -h "$HOME/.vim" ]]; then
        mv "$HOME/.vim" "${__rayrc_dir_data_vim}/__rayrc_backup/.vim"
    fi

    ### download plug.vim
    # __rayrc_url_downloader https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    #    "${__rayrc_dir_data_vim}/vimfiles/autoload/plug.vim"
    curl -fsLo "${__rayrc_dir_data_vim}/vimfiles/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    ### ln our vimfiles to ~/.vim
    ln -snf "${__rayrc_dir_data_vim}/vimfiles" ~/.vim

    vim -u "${__rayrc_dir_data_vim}/vimfiles/plugins.vim" +PlugInstall +qa >& /dev/null
    # echo "###### after PlugInstall #####"
    # pwd
    # ls -ahl "${__rayrc_dir_data_vim}/vimfiles"
    # ls -ahl "${__rayrc_dir_data_vim}/vimfiles/plugged"

}

__rayrc_install_vim
unset -f __rayrc_install_vim


