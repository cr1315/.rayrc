#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ -x "${__rayrc_bin_dir}/claude" ]]; then
        claude update
    fi

    ## bootstrap claude using its official installer
    (cd "${__rayrc_data_dir}" && curl -fsSL https://claude.ai/install.sh | bash >&/dev/null) || {
        echo "  .rayrc: failed to bootstrap claude"
        return 8
    }

    ## claude installs its binary to ~/.local/bin/claude — symlink into __rayrc_bin_dir
    if [[ -x "${HOME}/.local/bin/claude" ]]; then
        ln -snf "${HOME}/.local/bin/claude" "${__rayrc_bin_dir}/claude"
    fi

    ## ~/.claude → libs/claude (backup existing if not already our symlink)
    if [[ ! -L "${HOME}/.claude" || "$(readlink "${HOME}/.claude")" != "${__rayrc_data_dir}/.claude" ]]; then
        if [[ -e "${HOME}/.claude" ]]; then
            mv "${HOME}/.claude" "${HOME}/.claude_rayrc_bkup_$(date +%Y%m%d_%H%M%S)"
        fi
        ln -snf "${__rayrc_data_dir}/.claude" "${HOME}/.claude"
    fi

}

__rayrc_install
unset -f __rayrc_install
