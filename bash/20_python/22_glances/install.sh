#!/usr/bin/env bash

[[ -x "${__rayrc_bin_dir}/uv" ]] || { return; }

__rayrc_install() {
    __rayrc_module_common_setup

    if [[ ! -x "${__rayrc_bin_dir}/glances" ]]; then
        if [[ "${__rayrc_package_manager}" == "apk" ]]; then
            {
                apk add --no-cache --virtual .build-deps build-base python3-dev libffi-dev \
                && "${__rayrc_bin_dir}/uv" tool install --python 3.13 glances \
                && apk del .build-deps
            } >&/dev/null
        else
            "${__rayrc_bin_dir}/uv" tool install --python 3.13 "glances[cloud,containers]" >&/dev/null
        fi
    fi
}

__rayrc_install
unset -f __rayrc_install
