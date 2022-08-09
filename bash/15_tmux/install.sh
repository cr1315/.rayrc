#!/usr/bin/env bash

command -v tmux >/dev/null 2>&1 || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    # backup the user's .tmux.conf or even .tmux folder
    if [[ -f "${HOME}/.tmux.conf" && ! -L "${HOME}/.tmux.conf" ]]; then
        mv "${HOME}/.tmux.conf" "${__rayrc_data_dir}/__rayrc_backup/.tmux.conf"
    elif [[ -f "${HOME}/.tmux.conf" ]]; then
        rm -f "${HOME}/.tmux.conf"
    else
        true
    fi

    if [[ -d "$HOME/.tmux" && ! -L "$HOME/.tmux" ]]; then
        mv "$HOME/.tmux" "${__rayrc_data_dir}/__rayrc_backup/.tmux"
    fi

    #     "cat" <<EOF >>"$HOME/.tmux.conf"
    # source -q "${__rayrc_data_dir}/.tmux.conf"
    # source -q "${__rayrc_data_dir}/.tmux.conf.local"
    # EOF

    cp -f "${__rayrc_data_dir}/.tmux.conf"* "$HOME"

}

__rayrc_install
unset -f __rayrc_install
