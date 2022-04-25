#!/usr/bin/env bash


__rayrc_install_fd() {
    local __rayrc_dir_ctl_fd
    local __rayrc_dir_data_fd


    __rayrc_dir_ctl_fd="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_fd}: ${__rayrc_dir_ctl_fd}"

    __rayrc_dir_data_fd="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_fd}: ${__rayrc_dir_data_fd}"
    [[ ! -d "${__rayrc_dir_data_fd}" ]] && mkdir -p "${__rayrc_dir_data_fd}"

    __rayrc_github_downloader "sharkdp/fd" "${__rayrc_dir_data_fd}/fd.tar.gz" \
        `uname -m` `echo -n $OSTYPE`

    tar xf "${__rayrc_dir_data_fd}/fd.tar.gz" -C "${__rayrc_dir_data_fd}" --transform 's:^[^/]*:fd:'

    cp -f "${__rayrc_dir_data_fd}/fd/fd" "${__rayrc_dir_data_bin}"

    rm -rf "${__rayrc_dir_data_fd}/fd/"*
}

__rayrc_install_fd
unset -f __rayrc_install_fd


