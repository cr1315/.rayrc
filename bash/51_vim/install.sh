#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ ! -d "${__rayrc_data_dir}/__rayrc_backup" ]]; then
        mkdir -p "${__rayrc_data_dir}/__rayrc_backup"
    fi

    # backup the user's .vimrc or even .vim folder
    if [[ -f "$HOME/.vimrc" ]]; then
        mv "$HOME/.vimrc" "${__rayrc_data_dir}/__rayrc_backup/.vimrc"
    fi
    if [[ -d "$HOME/.vim" && ! -L "$HOME/.vim" ]]; then
        mv "$HOME/.vim" "${__rayrc_data_dir}/__rayrc_backup/.vim"
    fi

    ### download plug.vim
    # __rayrc_url_downloader https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    #    "${__rayrc_data_dir}/vimfiles/autoload/plug.vim"
    curl -fsLo "${__rayrc_data_dir}/vimfiles/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    ### ln our vimfiles to ~/.vim
    ln -snf "${__rayrc_data_dir}/vimfiles" ~/.vim

    vim -u "${__rayrc_data_dir}/vimfiles/plugins.vim" +PlugInstall +qa >&/dev/null
    # echo "###### after PlugInstall #####"
    # pwd
    # ls -ahl "${__rayrc_data_dir}/vimfiles"
    # ls -ahl "${__rayrc_data_dir}/vimfiles/plugged"

}

__rayrc_install
unset -f __rayrc_install
