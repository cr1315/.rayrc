#!/usr/bin/env bash

command -v lf >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    alias lf="XDG_CONFIG_HOME='${__rayrc_data_dir}/config' XDG_DATA_HOME='${__rayrc_data_dir}/data' lf"

}

__rayrc_main
unset -f __rayrc_main

lfcd() {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    # lf 終了時、tcell の端末問い合わせ応答が SSH ホップの遅延で lf 終了後に届く。
    # RTT を超える窓で最初の1バイトを待ち、来たら残りを一気に掃く。
    # (来なければ ~0.3s で抜けるだけ。lf 終了時のみのコストなので許容)
    read -r -t 0.3 -s 2>/dev/null && \
        while read -r -t 0.05 -n 4096 -s 2>/dev/null; do :; done
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
    # bind '"\C-o":"lfcd\C-m"'
    bind -x '"\C-o": lfcd'
fi
