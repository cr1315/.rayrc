#!/usr/bin/env bash

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
        "${__rayrc_dir_data_fzf}/fzf/install" --bin >&/dev/null

        cp -f "${__rayrc_dir_data_fzf}"/fzf/bin/* "${__rayrc_bin_dir}"

        # echo ""
        # echo "##### cat "${__rayrc_dir_data_fzf}/fzf/shell/completion.bash" #####"
        # cat "${__rayrc_dir_data_fzf}/fzf/shell/completion.bash"
        # echo ""
        # echo "##### cat "${__rayrc_dir_data_fzf}/fzf/shell/key-bindings.bash" #####"
        # cat "${__rayrc_dir_data_fzf}/fzf/shell/key-bindings.bash"

    else
        echo "##### $(command -v fzf) installed #####"
    fi
}

__rayrc_install_fzf
unset -f __rayrc_install_fzf
