#!/usr/bin/env zsh

# shortcut


__rayrc_fzf_install() {
    local __rayrc_fzf_install_dir=$1
    echo "\$__rayrc_fzf_install_dir: $__rayrc_fzf_install_dir"

    echo "##### ls fzf #####"
    ls -ahl "${__rayrc_fzf_install_dir}/fzf"

    if ! command -v fzf &> /dev/null; then
        echo "##### fzf not installed #####"
        git clone --depth 1 https://github.com/junegunn/fzf.git "${__rayrc_fzf_install_dir}/fzf"
        
        # we don't need to auto-generated configurations
        ${__rayrc_fzf_install_dir}/fzf/install --bin

        # echo "##### after fzf installed #####"
        # ls -ahl ~/

        # echo "##### cat ~/.fzf.zsh #####"
        # cat ~/.fzf.zsh
    else
        echo "##### $(command -v fzf) installed #####"
    fi

}

__rayrc_fzf_install ${0:A:h}
unset -f __rayrc_fzf_install
