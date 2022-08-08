#!/usr/bin/env zsh

__rayrc_delegate_main() {
    local __rayrc_package_manager
    local __rayrc_delegate_dir

    local __rayrc_root_dir
    local __rayrc_libs_dir
    local __rayrc_bin_dir

    __rayrc_delegate_dir=$1
    echo "\${__rayrc_delegate_dir}: ${__rayrc_delegate_dir}"

    # actually, this was a bug...
    # I couldn't calculate this much..
    __rayrc_root_dir="$(cd -- "${__rayrc_delegate_dir}/.." && pwd -P)"
    __rayrc_libs_dir="$(cd -- "${__rayrc_delegate_dir}/../libs" && pwd -P)"

    # determine the os type and set __rayrc_facts_os_type
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        __rayrc_facts_os_type="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        __rayrc_facts_os_type="macos"
    else
        echo ".rayrc: not supported OS by now.."
        return 8
    fi

    ### setup each package
    for package in $(ls -1 "${__rayrc_delegate_dir}"); do
        # echo "\${__rayrc_delegate_dir}/\${package}: ${__rayrc_delegate_dir}/${package}"
        if [[ -d "${__rayrc_delegate_dir}/${package}" &&
            -f "${__rayrc_delegate_dir}/${package}/main.zsh" &&
            ! -f "${__rayrc_delegate_dir}/${package}/disabled" ]]; then
            echo "\${__rayrc_delegate_dir}/\${package}: ${__rayrc_delegate_dir}/${package}"
            source "${__rayrc_delegate_dir}/${package}/main.zsh"
        fi
    done

}

__rayrc_delegate_main ${0:A:h}
unset -f __rayrc_delegate_main
