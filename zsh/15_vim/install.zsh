#!/usr/bin/env zsh

# shortcut


__rayrc_install_vim() {
    local __rayrc_install_vim_dir=$1
    echo "\$__rayrc_install_vim_dir: $__rayrc_install_vim_dir"


    local __rayrc_dir_ctl_raypm
    local __rayrc_dir_data_raypm


    __rayrc_dir_ctl_raypm=$1
    echo "\${__rayrc_dir_ctl_raypm}: ${__rayrc_dir_ctl_raypm}"

    echo "package: $package"
    echo "package[3..]: ${package:3}"

    __rayrc_dir_data_raypm="${__rayrc_dir_libs}/${package:3}"
    echo "\${__rayrc_dir_data_raypm}: ${__rayrc_dir_data_raypm}"


    ### download plug.vim
    curl -fLo "$__rayrc_dir_data_raypm/vimfiles/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    ### ln vimfiles to ~/.vim
    # mkdir ./rayrc_backup; [[ -f ~/.vimrc ]] && cp -fp ~/.vimrc ./rayrc_backup
    # determine & ln -snF
    ln -snf "$__rayrc_dir_data_raypm/vimfiles" ~/.vim


    # vim -u "$__rayrc_dir_data_raypm/vimfiles/plugins.vim" +PlugInstall +qa &> /dev/null
    vim -u "$__rayrc_dir_data_raypm/vimfiles/plugins.vim" +PlugInstall +qa
    echo "###### after PlugInstall #####"
    pwd
    ls -ahl "$__rayrc_dir_data_raypm/vimfiles"
    ls -ahl "$__rayrc_dir_data_raypm/vimfiles/plugged"

}

__rayrc_install_vim ${0:A:h}
unset -f __rayrc_install_vim
