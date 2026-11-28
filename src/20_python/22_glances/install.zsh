#!/usr/bin/env zsh

[[ -x "${__rayrc_bin_dir}/uv" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ ! -x "${__rayrc_bin_dir}/glances" ]]; then
        "${__rayrc_bin_dir}/uv" tool install --force --python 3.13 "glances[cloud,containers,ip]" >&/dev/null
    fi
}

__rayrc_install
unset -f __rayrc_install
