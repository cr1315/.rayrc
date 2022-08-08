#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_common_setup_module

    if [[ "${__rayrc_facts_os_type}" =~ "linux" ]]; then
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
    elif [[ "${__rayrc_facts_os_type}" =~ "macos" ]]; then
        if uname -m | grep -q "86" >&/dev/null; then
            __rayrc_github_downloader \
                "gokcehan/lf" "${__rayrc_data_dir}/lf.tar.gz" \
                "darwin" "amd64"
        # elif uname -m | grep -E -q "arm|aarch" >& /dev/null; then
        #     __rayrc_github_downloader \
        #         "BurntSushi/ripgrep" "${__rayrc_data_dir}/lf.tar.gz" \
        #         "darwin" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading lf.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading lf.."
        return 8
    fi

    tar xf "${__rayrc_data_dir}/lf.tar.gz" -C "${__rayrc_data_dir}"

    cp -f "${__rayrc_data_dir}/lf" "${__rayrc_bin_dir}"

    rm -rf "${__rayrc_data_dir}/lf"*
}

__rayrc_install
unset -f __rayrc_install
