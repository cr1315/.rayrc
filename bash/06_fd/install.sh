#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    __rayrc_github_downloader "sharkdp/fd" "${__rayrc_data_dir}/fd.tar.gz" \
        $(uname -m) $(echo -n $OSTYPE)

    tar xf "${__rayrc_data_dir}/fd.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:fd:'

    cp -f "${__rayrc_data_dir}/fd/fd" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/fd"*
}

__rayrc_install
unset -f __rayrc_install
