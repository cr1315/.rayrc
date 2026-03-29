#!/usr/bin/env bash

## niri is a Wayland compositor — skip on non-Wayland systems
## check: Wayland session active, WSLg available, or wayland dev tools installed
if [[ -z "${WAYLAND_DISPLAY}" ]] &&
   [[ ! -d /mnt/wslg ]] &&
   [[ ! -f /usr/share/wayland/wayland.xml ]] &&
   ! command -v wayland-scanner >/dev/null 2>&1; then
    __rayrc_log_info "Wayland not available, skipping niri"
    return
fi

__rayrc_install() {
    __rayrc_module_common_setup
    __rayrc_source_facade install
}

__rayrc_install
unset -f __rayrc_install
