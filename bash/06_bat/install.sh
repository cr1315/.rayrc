#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_github_downloader "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
        $(uname -m) "musl"

    ls -Ahl "${__rayrc_data_dir}"

    tar xvf "${__rayrc_data_dir}/bat.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:bat:'

    cp -f "${__rayrc_data_dir}/bat/bat" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/bat"*
}

__rayrc_install
unset -f __rayrc_install
