#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    ## download lf.tar.gz
    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -q "86" >&/dev/null; then
            if uname -m | grep -q "64" >&/dev/null; then
                __rayrc_github_downloader \
                    "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                    "linux" "amd64"
            else
                __rayrc_github_downloader \
                    "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                    "linux" "386"
            fi
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            if uname -m | grep -q "64" >&/dev/null; then
                __rayrc_github_downloader \
                    "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                    "linux" "arm64"
            else
                __rayrc_github_downloader \
                    "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                    "linux" "arm"
            fi
        else
            echo ".rayrc: unsupported cpu architecture for downloading lf.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -q "86" >&/dev/null; then
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "darwin" "amd64"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "darwin" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading lf.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading lf.."
        return 8
    fi

    ## install to my bin dir
    tar xf "${__rayrc_data_dir}/lf.tar.gz" -C "${__rayrc_data_dir}"
    cp -f "${__rayrc_data_dir}/lf" "${__rayrc_bin_dir}"

    ## clean
    rm -rf "${__rayrc_data_dir}/lf"*

    ## preapre for lfrc
    if [[ ! -d "${HOME}/.cache/lf" ]]; then
        mkdir -p "${HOME}/.cache/lf"
    fi
    cp -f "${__rayrc_data_dir}/config/lf/"*preview* "${__rayrc_bin_dir}"

}

__rayrc_install
unset -f __rayrc_install
