#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -x "${__rayrc_bin_dir}/claude" ]]; then
        return 0
    fi

    ## bootstrap claude using its official installer
    (cd "${__rayrc_data_dir}" && curl -fsSL https://claude.ai/install.sh | bash) || {
        echo "  .rayrc: failed to bootstrap claude"
        return 8
    }

    ## claude installs its binary to ~/.local/bin/claude — symlink into __rayrc_bin_dir
    if [[ -x "${HOME}/.local/bin/claude" ]]; then
        ln -snf "${HOME}/.local/bin/claude" "${__rayrc_bin_dir}/claude"
    fi
}

__rayrc_install
unset -f __rayrc_install
