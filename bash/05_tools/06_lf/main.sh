#!/usr/bin/env bash

command -v lf >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## TCELL_KEYBOARD_PROTOCOL=legacy: lf r42 で tcell v2->v3 に移行し(#2286)、
    ## v3 は kitty keyboard protocol(\e[=15u)を有効化する。フラグ15にはキー離上
    ## イベント報告が含まれ、`q` で抜ける際の離上報告が多段SSH(ProxyJump)の遅延で
    ## lf 終了後に届き、次のプロンプトへ生エスケープ列として漏れる。legacy を強制
    ## すると kitty の問い合わせ・有効化を一切送らなくなり、発生源から断てる。
    alias lf="XDG_CONFIG_HOME='${__rayrc_data_dir}/config' XDG_DATA_HOME='${__rayrc_data_dir}/data' TCELL_KEYBOARD_PROTOCOL=legacy lf"

}

__rayrc_main
unset -f __rayrc_main

lfcd() {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$("cat" "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ]; then
            if [ "$dir" != "$(pwd)" ]; then
                cd "$dir"
            fi
        fi
    fi
}

if [[ $- == *i* ]]; then
    ## bind -x still leak `;16;113;0;32;1_`
    # bind -x '"\C-o": lfcd'
    bind '"\C-o":"lfcd\C-m"'
fi
