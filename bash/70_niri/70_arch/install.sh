#!/usr/bin/env bash

[[ "${__rayrc_facts_os_distribution}" == "arch" ]] || return

__rayrc_install() {
    __rayrc_module_common_setup

    ## niri dependencies + niri itself
    local packages=(
        wayland
        wayland-protocols
        libinput
        mesa
        seatd
        pipewire
        wireplumber
        xdg-desktop-portal-gnome
        niri
    )

    sudo pacman -S --needed --noconfirm "${packages[@]}" || {
        __rayrc_log_info "failed to install niri packages"
        return 8
    }
}

__rayrc_install
unset -f __rayrc_install
