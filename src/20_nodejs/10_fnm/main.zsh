#!/usr/bin/env zsh

command -v fnm >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## Node versions live under libs/nodejs/fnm (same as main.sh)
    export FNM_DIR="${__rayrc_data_dir}"

    ## `fnm env` prepends a new per-shell dir on every call and never drops the
    ## ones inherited from the parent shell, so nested shells (exec zsh, tmux)
    ## pile them up. Drop the inherited ones first (path is tied to PATH): the
    ## one prepended below shadows them anyway.
    path=("${(@)path:#*/fnm_multishells/*}")

    ## --use-on-cd: in zsh this hooks chpwd (no `cd` alias as in bash)
    eval "$(fnm env --shell zsh --use-on-cd)"

    ## ...and fnm never removes those per-shell links (symlinks to a Node version).
    ## Linux keeps them on tmpfs (/run/user/<uid>, gone at logout), macOS in
    ## ~/.local/state for good. Which ones other shells still use cannot be told,
    ## so a login shell drops the ones untouched for 7 days, except its own.
    ## `fnm use` re-creates a link (bumping its time); a shell open that long
    ## whose link was dropped gets node back with `fnm use default`.
    if [[ -o login && -n "${FNM_MULTISHELL_PATH}" ]]; then
        find "${FNM_MULTISHELL_PATH:h}" -mindepth 1 -maxdepth 1 -type l -mtime +7 \
            ! -path "${FNM_MULTISHELL_PATH}" -delete 2>/dev/null
    fi

    ## completion needs compinit, which rayrc does not run itself
    (( ${+functions[compdef]} )) && eval "$(fnm completions --shell zsh)" 2>/dev/null
}

__rayrc_main
unset -f __rayrc_main
