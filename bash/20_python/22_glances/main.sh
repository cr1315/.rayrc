#!/usr/bin/env bash

command -v glances >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    ## Synology の ncurses は terminfo の数値 65536 を clamp せず下位 16bit へ truncate
    ## するため、DSM 同梱の terminfo では glances が起動できない。正常な環境(EC2)で
    ## 生成した terminfo を同梱しているので、このユーザーだけそちらを優先させる。
    ## 末尾の ':' はシステム既定の検索パスへのフォールバック。
    if [[ "${__rayrc_facts_os_distribution}" == "Synology" ]]; then
        unset TERMINFO    # DSM の /etc/profile 由来の上書きを解除
        export TERMINFO_DIRS="${__rayrc_data_dir}/share/terminfo:"
    fi

}

__rayrc_main
unset -f __rayrc_main
