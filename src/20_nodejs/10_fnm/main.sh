#!/usr/bin/env bash

command -v fnm >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## Node versions live under libs/nodejs/fnm. The per-shell symlinks that
    ## `fnm env` creates go to $XDG_RUNTIME_DIR/fnm_multishells (ephemeral).
    export FNM_DIR="${__rayrc_data_dir}"

    ## `fnm env` prepends a new per-shell dir on every call and never drops the
    ## ones inherited from the parent shell, so nested shells (exec bash, tmux)
    ## pile them up. Drop the inherited ones first: the one prepended below
    ## shadows them anyway.
    local p=":${PATH}:"
    while [[ "${p}" =~ :[^:]*/fnm_multishells/[^:]*: ]]; do
        p="${p/"${BASH_REMATCH[0]}"/:}"
    done
    p="${p#:}"
    PATH="${p%:}"

    ## --use-on-cd switches Node by .node-version / .nvmrc / package.json;
    ## note that it does so by defining `alias cd=__fnmcd`.
    eval "$(fnm env --shell bash --use-on-cd)"

    ## ...and fnm never removes those per-shell links (symlinks to a Node version).
    ## Linux keeps them on tmpfs (/run/user/<uid>, gone at logout), macOS in
    ## ~/.local/state for good. Which ones other shells still use cannot be told,
    ## so a login shell drops the ones untouched for 7 days, except its own.
    ## `fnm use` re-creates a link (bumping its time); a shell open that long
    ## whose link was dropped gets node back with `fnm use default`.
    if shopt -q login_shell && [[ -n "${FNM_MULTISHELL_PATH}" ]]; then
        find "${FNM_MULTISHELL_PATH%/*}" -mindepth 1 -maxdepth 1 -type l -mtime +7 \
            ! -path "${FNM_MULTISHELL_PATH}" -delete 2>/dev/null
    fi
    eval "$(fnm completions --shell bash)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
