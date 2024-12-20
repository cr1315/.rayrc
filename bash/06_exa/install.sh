#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/exa" "${__rayrc_data_dir}/exa.zip" \
                "arm" "linux"
        elif uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/exa" "${__rayrc_data_dir}/exa.zip" \
                "musl" "x86_64"
        else
            echo ".rayrc: unsupported cpu architecture for downloading exa.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/exa" "${__rayrc_data_dir}/exa.zip" \
                "macos" "x86"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/exa" "${__rayrc_data_dir}/exa.zip" \
                "macos" "arm"
        else
            echo ".rayrc: unsupported cpu architecture for downloading exa.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading exa.."
        return 8
    fi

    if [[ $? -ne 0 ]]; then
        echo "  .rayrc: failed to setup ${__rayrc_package:3}"
        return 8
    fi

    if command -v unzip >/dev/null 2>&1; then

        unzip "${__rayrc_data_dir}/exa.zip" -d "${__rayrc_data_dir}/exa/" >/dev/null 2>&1
        cp -f "${__rayrc_data_dir}/exa/bin/exa" "${__rayrc_bin_dir}"
        rm -rf "${__rayrc_data_dir}/exa"*

    elif command -v 7z >/dev/null 2>&1; then

        7z x "${__rayrc_data_dir}/exa.zip" -o"${__rayrc_data_dir}/exa/" >/dev/null 2>&1
        cp -f "${__rayrc_data_dir}/exa/bin/exa" "${__rayrc_bin_dir}"
        rm -rf "${__rayrc_data_dir}/exa"*

    else
        echo ".rayrc: unzip or 7z is required to install exa.."
        return 8
    fi
}

__rayrc_install
unset -f __rayrc_install
