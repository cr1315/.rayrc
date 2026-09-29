#!/usr/bin/env bash

command -v lf >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    alias lf="XDG_CONFIG_HOME='${__rayrc_data_dir}/config' XDG_DATA_HOME='${__rayrc_data_dir}/data' lf"

}

__rayrc_main
unset -f __rayrc_main

# lf(tcell) が全画面 TUI を抜けた後、端末への問い合わせ応答が tty 入力に
# 残る/遅れて届くことがある。ProxyJump など多段 SSH では応答が lf 終了後に
# 届き、次のプロンプトに生のエスケープ列 (例: ";16;113;0;32;1_") として漏れる。
# 時間待ちドレインでは直らない — バイトがまだ飛行中なら掃きようがないため。
# そこで端末と「同期」する: 自分でカーソル位置報告(CSI 6 n)を要求し、その応答
# (CSI row ; col R) が返るまで読み捨てる。tty のバイト列は順序保証があるので、
# lf が残した迷子応答は必ず我々の応答より先に届き、ここで確実に飲み込まれる。
# レイテンシに依存しないのが要点(速い経路では即 R が返り無害)。
__rayrc_lf_sync_tty() {
    [[ $- == *i* ]] || return 0
    [ -t 0 ] && [ -t 1 ] || return 0
    local c
    printf '\033[6n' >/dev/tty
    while IFS= read -rsn1 -t 1 c 2>/dev/null; do
        [[ $c == R ]] && break
    done
}

lfcd() {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    __rayrc_lf_sync_tty
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
