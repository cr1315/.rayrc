#!/usr/bin/env bash

command -v yazi >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## yazi.toml, keymap.toml, theme.toml, init.lua, plugins/, flavors/ all
    ## live here; `ya pkg` also installs plugins/flavors into this dir.
    export YAZI_CONFIG_HOME="${__rayrc_data_dir}/config"

    local __rayrc_yazi_completion
    for __rayrc_yazi_completion in "${__rayrc_ctl_dir}/completions/"{yazi,ya}.bash; do
        [[ -f "${__rayrc_yazi_completion}" ]] && source "${__rayrc_yazi_completion}"
    done
}

__rayrc_main
unset -f __rayrc_main

## y: yazi 終了時のディレクトリへ cd する公式シェルラッパー
## https://yazi-rs.github.io/docs/quick-start#shell-wrapper
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

## lf (05_tools/06_lf) と同じ C-o を上書きする。yazi が入っていなければ
## 冒頭の guard で return するので lfcd のまま残る。
if [[ $- == *i* ]]; then
    ## bind -x leaks `;16;113;0;32;1_` (see 06_lf/main.sh)
    bind '"\C-o":"y\C-m"'
fi
