#!/usr/bin/env bash

common_setup() {

    echo "inside common_setup: \${BASH_SOURCE[0]}: ${BASH_SOURCE[0]}"

    __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/${__rayrc_package}"
    echo "inside common_setup: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    echo "inside common_setup: \${__rayrc_data_dir}: ${__rayrc_data_dir}"

}

parent() {

    local __rayrc_ctl_dir
    local __rayrc_data_dir

    local __rayrc_delegate_dir
    __rayrc_delegate_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

    local __rayrc_package
    for __rayrc_package in $(ls -1 "${__rayrc_delegate_dir}"); do

        # echo "\${__rayrc_delegate_dir}/\${__rayrc_package}: ${__rayrc_delegate_dir}/${__rayrc_package}"
        if [[ -d "${__rayrc_delegate_dir}/${__rayrc_package}" && -f "${__rayrc_delegate_dir}/${__rayrc_package}/install.sh" ]]; then
            echo ".rayrc: setting up for ${__rayrc_package:3}.."
            source "${__rayrc_delegate_dir}/${__rayrc_package}/install.sh"
        fi

    done

    # __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    echo "inside parent: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    # __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    echo "inside parent: \${__rayrc_data_dir}: ${__rayrc_data_dir}"

}

parent

# __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
echo "after calling parent: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

# __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
echo "after calling parent: \${__rayrc_data_dir}: ${__rayrc_data_dir}"

unset -f parent
unset -f common_setup

# __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
echo "after destroying parent: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

# __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
echo "after destroying parent: \${__rayrc_data_dir}: ${__rayrc_data_dir}"
