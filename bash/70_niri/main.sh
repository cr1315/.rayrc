#!/usr/bin/env bash

command -v niri >/dev/null 2>&1 || { return; }

__rayrc_main() {
    __rayrc_module_common_setup

    export MESA_LOADER_DRIVER_OVERRIDE=d3d12
    export GALLIUM_DRIVER=d3d12
    export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA

}

__rayrc_main
unset -f __rayrc_main
