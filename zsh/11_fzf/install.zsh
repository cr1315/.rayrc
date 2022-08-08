#!/usr/bin/env zsh

# shortcut

__rayrc_install_fzf() {
    local __rayrc_dir_ctl_fzf
    local __rayrc_dir_data_fzf

    __rayrc_dir_ctl_fzf=$1
    # echo "\${__rayrc_dir_ctl_fzf}: ${__rayrc_dir_ctl_fzf}"

    __rayrc_dir_data_fzf="${__rayrc_libs_dir}/${package:3}"
    # echo "\${__rayrc_dir_data_fzf}: ${__rayrc_dir_data_fzf}"
    if [[ ! -d ${__rayrc_dir_data_fzf} ]]; then
        mkdir -p ${__rayrc_dir_data_fzf}
    fi

    if ! command -v fzf >&/dev/null; then

        # echo "##### fzf not installed #####"
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git \
            "${__rayrc_dir_data_fzf}/fzf" >&/dev/null

        # we don't need to auto-generated configurations
        ${__rayrc_dir_data_fzf}/fzf/install --bin

        cp -f "${__rayrc_dir_data_fzf}"/fzf/bin/* "${__rayrc_bin_dir}"

    else
        echo "##### $(command -v fzf) installed #####"
    fi

}

__rayrc_install_fzf ${0:A:h}
unset -f __rayrc_install_fzf
