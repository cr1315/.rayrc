#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ ! -d "${__rayrc_data_dir}/__rayrc_backup" ]]; then
        mkdir -p "${__rayrc_data_dir}/__rayrc_backup"
    fi

    # backup the user's .vimrc or even .vim folder
    if [[ -f "${HOME}/.vimrc" && ! -L "${HOME}/.vimrc" ]]; then
        mv "${HOME}/.vimrc" "${__rayrc_data_dir}/__rayrc_backup/.vimrc"
    elif [[ -f "${HOME}/.vimrc" ]]; then
        rm -f "${HOME}/.vimrc"
    else
        true
    fi
    if [[ -d "${HOME}/.vim" && ! -L "${HOME}/.vim" ]]; then
        mv "${HOME}/.vim" "${__rayrc_data_dir}/__rayrc_backup/.vim"
    fi

    ### download plug.vim
    curl -fLo "${__rayrc_data_dir}/vimfiles/autoload/plug.vim" --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    # determine & ln -snF
    ln -snf "${__rayrc_data_dir}/vimfiles" ~/.vim

    vim -u "${__rayrc_data_dir}/vimfiles/plugins.vim" +PlugInstall +qa >&/dev/null
    # echo "###### after PlugInstall #####"
    # pwd
    # ls -ahl "${__rayrc_data_dir}/vimfiles"
    # ls -ahl "${__rayrc_data_dir}/vimfiles/plugged"

}

__rayrc_install ${0:A:h}
unset -f __rayrc_install
