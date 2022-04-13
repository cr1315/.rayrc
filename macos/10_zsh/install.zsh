#!/usr/bin/env zsh

# shortcut


__rayrc_zsh_install() {
    local __rayrc_zsh_install_dir=$1
    echo "\$__rayrc_zsh_install_dir: $__rayrc_zsh_install_dir"

    ### install oh-my-zsh if not
    if [[ ! -v ZSH ]]; then
        # sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        curl -fsSL -o omz_install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        ZSH="$__rayrc_zsh_install_dir/oh-my-zsh" sh omz_install.sh


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

__rayrc_zsh_install ${0:A:h}
unset -f __rayrc_zsh_install
