#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ "${__rayrc_facts_os_type}" == "linux" ]]; then
        if uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            if uname -m | grep -q "64" >&/dev/null; then
                __rayrc_github_downloader \
                    "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                    'linux_arm64"'
            else
                __rayrc_github_downloader \
                    "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                    'linux_arm"'
            fi
        elif uname -m | grep -q "86" >&/dev/null; then
            if uname -m | grep -q "64" >&/dev/null; then
                __rayrc_github_downloader \
                    "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                    'linux_amd64"'
            else
                __rayrc_github_downloader \
                    "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                    'linux_386"'
            fi
        else
            echo ".rayrc: unsupported cpu architecture for downloading lf.."
            return 8
        fi
    elif [[ "${__rayrc_facts_os_type}" == "macos" ]]; then
        if uname -m | grep -q "86" >&/dev/null; then
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'darwin_amd64"'
        elif uname -m | grep -E -q "arm|aarch" >&/dev/null; then
            __rayrc_github_downloader \
                "mikefarah/yq" "${__rayrc_data_dir}/yq" \
                'darwin_arm64"'
        else
            echo ".rayrc: unsupported cpu architecture for downloading lf.."
            return 8
        fi
    else
        echo ".rayrc: unsupported os for downloading lf.."
        return 8
    fi

    mv -f "${__rayrc_data_dir}/yq" "${__rayrc_bin_dir}"
    chmod -R 755 "${__rayrc_bin_dir}"
    rm -rf "${__rayrc_data_dir}/yq"*
}

__rayrc_install
unset -f __rayrc_install
