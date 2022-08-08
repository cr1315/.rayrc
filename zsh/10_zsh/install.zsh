#!/usr/bin/env zsh

__rayrc_install() {
    local __rayrc_ctl_dir
    local __rayrc_data_dir

    __rayrc_ctl_dir=$1
    # echo "\${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_data_dir}: ${__rayrc_data_dir}"

    if [[ ! -d ${__rayrc_data_dir} ]]; then
        mkdir -p ${__rayrc_data_dir}
    fi

    ### install oh-my-zsh if not
    if [[ ! -v ZSH ]]; then
        # sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        curl -fsSL -o "${__rayrc_data_dir}/omz_install.sh" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        ZSH="${__rayrc_data_dir}/oh-my-zsh" sh "${__rayrc_data_dir}/omz_install.sh"

        sed -i -e 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $HOME/.zshrc

        #
        # TODO: setup .zshrc

        # source $HOME/.zshrc
        # what about `exec zsh`
        # exec zsh

        # echo "##### zsh-variables #####"
        # set | grep ^ZSH
    fi

}

__rayrc_install ${0:A:h}
unset -f __rayrc_install
