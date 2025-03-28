#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/eza" "${__rayrc_data_dir}/eza.zip" \
                "arm" "linux"
        elif uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/eza" "${__rayrc_data_dir}/eza.zip" \
                "musl" "x86_64"
        else
            echo ".rayrc: unsupported cpu architecture for downloading eza.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -E -q "86|ia64" >&/dev/null; then
            __rayrc_github_downloader \
                "ogham/eza" "${__rayrc_data_dir}/eza.zip" \
                "macos" "x86"
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            ${__rayrc_pm_update_repo} >&/dev/null
            ${__rayrc_package_manager} install eza &>/dev/null
        else
            echo ".rayrc: unsupported cpu architecture for downloading eza.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading eza.."
        return 8
    fi

    if [[ $? -ne 0 ]]; then
        echo "  .rayrc: failed to setup ${__rayrc_package:3}"
        return 8
    fi

    if [[ -f "${__rayrc_data_dir}/eza.zip" ]]; then
        command -v unzip >/dev/null 2>&1 || { return; }

        unzip "${__rayrc_data_dir}/eza.zip" -d "${__rayrc_data_dir}/eza/" >/dev/null 2>&1
        cp -f "${__rayrc_data_dir}/eza/bin/eza" "${__rayrc_bin_dir}"
        rm -rf "${__rayrc_data_dir}/eza"*
    fi
}

__rayrc_install
unset -f __rayrc_install
