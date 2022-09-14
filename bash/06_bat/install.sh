#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_github_downloader "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" \
        $(uname -m) "musl"

    if [[ $? -ne 0 ]]; then
        echo "  .rayrc: failed to setup ${__rayrc_package:3}"
        return 8
    fi

    tar xvf "${__rayrc_data_dir}/bat.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:bat:'

    cp -f "${__rayrc_data_dir}/bat/bat" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/bat"*
}

__rayrc_install
unset -f __rayrc_install
