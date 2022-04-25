#!/usr/bin/env bash


__rayrc_install_rg() {
    local __rayrc_dir_ctl_rg
    local __rayrc_dir_data_rg


    __rayrc_dir_ctl_rg="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_dir_ctl_rg}: ${__rayrc_dir_ctl_rg}"

    __rayrc_dir_data_rg="${__rayrc_dir_libs}/${package:3}"
    # echo "\${__rayrc_dir_data_rg}: ${__rayrc_dir_data_rg}"
    [[ ! -d "${__rayrc_dir_data_rg}" ]] && mkdir -p "${__rayrc_dir_data_rg}"


    if [[ "${__rayrc_stat_os}" =~ "linux" ]]; then
        if uname -m | grep -E -q "86|ia64" >& /dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_dir_data_rg}/rg.tar.gz" \
                "linux" "86"
        elif uname -m | grep -E -q "arm|aarch" >& /dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_dir_data_rg}/rg.tar.gz" \
                "linux" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading rg.."
            return 8
        fi
    elif [[ "${__rayrc_stat_os}" =~ "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >& /dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_dir_data_rg}/rg.tar.gz" \
                "darwin" "x86"
        elif uname -m | grep -E -q "arm|aarch" >& /dev/null; then
            __rayrc_github_downloader \
                "BurntSushi/ripgrep" "${__rayrc_dir_data_rg}/rg.tar.gz" \
                "linux" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading rg.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading rg.."
        return 8
    fi

    tar xf "${__rayrc_dir_data_rg}/rg.tar.gz" -C "${__rayrc_dir_data_rg}" --transform 's:^[^/]*:rg:'

    cp -f "${__rayrc_dir_data_rg}/rg/rg" "${__rayrc_dir_data_bin}"

    rm -rf "${__rayrc_dir_data_rg}/*"
}

__rayrc_install_rg
unset -f __rayrc_install_rg


