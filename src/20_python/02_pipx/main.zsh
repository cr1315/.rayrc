#!/usr/bin/env zsh

command -v pipx >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export PIPX_HOME="${__rayrc_data_dir}/run"
    export PIPX_BIN_DIR="${__rayrc_bin_dir}"

    ## argcomplete's completion is a bash `complete` script; zsh runs it through bashcompinit,
    ## which (like any zsh completion) needs compinit — rayrc does not run it itself
    (( ${+functions[compdef]} )) || return 0

    local pipx_complete_path
    pipx_complete_path="${$(command -v pipx):A:h}/register-python-argcomplete"
    if [[ -f "${pipx_complete_path}" ]]; then
        autoload -U +X bashcompinit && bashcompinit
        eval "$("${pipx_complete_path}" pipx)"
    fi
}

__rayrc_main
unset -f __rayrc_main
