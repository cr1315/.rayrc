#!/usr/bin/env zsh

# shortcut

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

    if ! command -v fzf >&/dev/null; then

        # echo "##### fzf not installed #####"
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git \
            "${__rayrc_data_dir}/fzf" >&/dev/null

        # we don't need to auto-generated configurations
        ${__rayrc_data_dir}/fzf/install --bin

        cp -f "${__rayrc_data_dir}"/fzf/bin/* "${__rayrc_bin_dir}"

    else
        echo "##### $(command -v fzf) installed #####"
    fi

}

__rayrc_install ${0:A:h}
unset -f __rayrc_install
