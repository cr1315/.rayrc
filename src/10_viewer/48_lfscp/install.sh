#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## 実行ファイル lfscp を libs/bin に置く（PATH に乗るので、対話・navi・lf から lfscp で呼べる）
    ## 実体は src に置いたまま、リンクだけを張る（git pull で中身が更新される。冪等）
    ## Windows の lfscp はリンクではなく src の実体をフルパスで呼ぶ（main.ps1 を参照）
    ln -snf "${__rayrc_ctl_dir}/lfscp" "${__rayrc_bin_dir}/lfscp" || {
        __rayrc_log_warn "failed to link lfscp"
        return 8
    }
}

__rayrc_install
unset -f __rayrc_install
