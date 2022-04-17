#!/usr/bin/env zsh

# shortcut


__rayrc_install_fzf() {
    local __rayrc_dir_ctl_fzf
    local __rayrc_dir_data_fzf


    __rayrc_dir_ctl_fzf=$1
    # echo "\${__rayrc_dir_ctl_fzf}: ${__rayrc_dir_ctl_fzf}"

    __rayrc_dir_data_fzf="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_fzf}: ${__rayrc_dir_data_fzf}"


    echo ""
    echo ""
    echo "##### ls fzf #####"
    ls -ahl "${__rayrc_dir_data_fzf}/fzf"

    if ! command -v fzf &> /dev/null; then
        echo "##### fzf not installed #####"
        git clone --depth 1 https://github.com/junegunn/fzf.git "${__rayrc_dir_data_fzf}/fzf"
        
        # we don't need to auto-generated configurations
        ${__rayrc_dir_data_fzf}/fzf/install --bin

        echo "##### after fzf installed #####"
        ls -ahl ~/

        echo "##### cat ~/.fzf.zsh #####"
        cat ~/.fzf.zsh
    else
        echo "##### $(command -v fzf) installed #####"
    fi

}

__rayrc_install_fzf ${0:A:h}
unset -f __rayrc_install_fzf
