#!/usr/bin/env zsh

# shortcut

__rayrc_install() {
    __rayrc_module_common_setup

    if ! command -v fzf >&/dev/null; then

        # echo "##### fzf not installed #####"
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git \
            "${__rayrc_data_dir}/fzf" >&/dev/null

        # we don't need to auto-generated configurations
        "${__rayrc_data_dir}/fzf/install" --bin >&/dev/null

        cp -f "${__rayrc_data_dir}"/fzf/bin/* "${__rayrc_bin_dir}"

    else
        echo ""
        echo "##### $(command -v fzf) installed #####"
        echo ""
    fi
}

__rayrc_install ${0:A:h}
unset -f __rayrc_install
