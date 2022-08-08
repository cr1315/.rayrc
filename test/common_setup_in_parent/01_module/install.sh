#!/usr/bin/env bash

__rayrc_main() {
    echo "inside module: \${BASH_SOURCE[0]}: ${BASH_SOURCE[0]}"

    common_setup

    # __rayrc_ctl_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    echo "inside module: \${__rayrc_ctl_dir}: ${__rayrc_ctl_dir}"

    # __rayrc_data_dir="${__rayrc_libs_dir}/${__rayrc_package:3}"
    echo "inside module: \${__rayrc_data_dir}: ${__rayrc_data_dir}"
}

__rayrc_main
unset -f __rayrc_main
