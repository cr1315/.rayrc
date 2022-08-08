#!/usr/bin/env zsh

__rayrc_install() {
    local __rayrc_ctl_dir
    local __rayrc_data_dir

    __rayrc_ctl_dir=$1
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_data_dir}: ${__rayrc_data_dir}"

    ### download plug.vim
    curl -fLo "${__rayrc_data_dir}/vimfiles/autoload/plug.vim" --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    ### ln vimfiles to ~/.vim
    # mkdir ./rayrc_backup; [[ -f ~/.vimrc ]] && cp -fp ~/.vimrc ./rayrc_backup
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
