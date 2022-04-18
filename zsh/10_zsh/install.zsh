#!/usr/bin/env zsh

__rayrc_install_zsh() {
    local __rayrc_dir_ctl_zsh
    local __rayrc_dir_data_zsh


    __rayrc_dir_ctl_zsh=$1
    # echo "\${__rayrc_dir_ctl_zsh}: ${__rayrc_dir_ctl_zsh}"

    __rayrc_dir_data_zsh="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_zsh}: ${__rayrc_dir_data_zsh}"

    if [[ ! -d ${__rayrc_dir_data_zsh} ]]; then
        mkdir -p ${__rayrc_dir_data_zsh}
    fi


    ### install oh-my-zsh if not
    if [[ ! -v ZSH ]]; then
        # sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        curl -fsSL -o "${__rayrc_dir_data_zsh}/omz_install.sh" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        ZSH="${__rayrc_dir_data_zsh}/oh-my-zsh" sh "${__rayrc_dir_data_zsh}/omz_install.sh"

        sed -i -e 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $HOME/.zshrc

        #
        # TODO: setup .zshrc

        # check results
        echo "##### .zshrc #####"
        cat $HOME/.zshrc

        source $HOME/.zshrc
        # what about `exec zsh`
        # exec zsh

        echo "##### zsh-variables #####"
        set | grep ^ZSH
    fi

}

__rayrc_install_zsh ${0:A:h}
unset -f __rayrc_install_zsh
