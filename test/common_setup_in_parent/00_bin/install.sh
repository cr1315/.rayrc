#!/usr/bin/env bash

__rayrc_main() {

    # __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    # echo "\${__rayrc_ctl_dir} for bin: " "$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

    # __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    # echo "\${__rayrc_data_dir} for bin: ${__rayrc_data_dir}" "${__rayrc_libs_dir}/${__rayrc_package:3}"
    echo "inside bin: \${BASH_SOURCE[0]}: ${BASH_SOURCE[0]}"

    common_setup

    # __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    echo "inside bin: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    # __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    echo "inside bin: \${__rayrc_data_dir}: ${__rayrc_data_dir}"
}

__rayrc_main
unset -f __rayrc_main
