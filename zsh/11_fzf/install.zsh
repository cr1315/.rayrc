#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup

    rm -rf "${__rayrc_data_dir}/fzf"

    # echo "##### fzf not installed #####"
    git clone --quiet --depth 1 https://github.com/junegunn/fzf.git \
        "${__rayrc_data_dir}/fzf" >&/dev/null

    # we don't need to auto-generated configurations
    "${__rayrc_data_dir}/fzf/install" --bin >&/dev/null

    cp -f "${__rayrc_data_dir}"/fzf/bin/* "${__rayrc_bin_dir}"
}

__rayrc_install
unset -f __rayrc_install
