#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_common_setup_module

    if ! command -v fzf >&/dev/null; then

        # echo "##### fzf not installed #####"
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git \
            "${__rayrc_data_dir}/fzf" >&/dev/null

        # we don't need to auto-generated configurations
        "${__rayrc_data_dir}/fzf/install" --bin >&/dev/null

        cp -f "${__rayrc_data_dir}"/fzf/bin/* "${__rayrc_bin_dir}"

        # echo ""
        # echo "##### cat "${__rayrc_data_dir}/fzf/shell/completion.bash" #####"
        # cat "${__rayrc_data_dir}/fzf/shell/completion.bash"
        # echo ""
        # echo "##### cat "${__rayrc_data_dir}/fzf/shell/key-bindings.bash" #####"
        # cat "${__rayrc_data_dir}/fzf/shell/key-bindings.bash"

    else
        echo "##### $(command -v fzf) installed #####"
    fi
}

__rayrc_install
unset -f __rayrc_install
