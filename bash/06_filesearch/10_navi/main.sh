#!/usr/bin/env bash

command -v navi >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export NAVI_CONFIG="${__rayrc_data_dir}/config/config.yaml"
    ## ホストごとに $HOME が異なるため、config.yaml の cheats.paths に絶対パスを
    ## 書かず NAVI_PATH で指定する (NAVI_PATH は config.yaml の cheats.paths より優先)
    export NAVI_PATH="${__rayrc_data_dir}/cheats"

}

__rayrc_main
unset -f __rayrc_main
