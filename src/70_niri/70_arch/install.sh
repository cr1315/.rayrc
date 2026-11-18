#!/usr/bin/env bash

## arch + wsl2 only
[[ "${__rayrc_facts_os_distribution}" == "arch" ]] || return
grep -qi microsoft /proc/version 2>/dev/null || return

__rayrc_install() {
    __rayrc_module_common_setup

    ## niri (required deps are pulled automatically by pacman)
    ## optional deps for a functional desktop
    local packages=(
        niri
        xdg-desktop-portal-gnome
        xwayland-satellite
        pipewire
        wireplumber
        fuzzel
        alacritty
        mako
        waybar
        swaybg
        swaylock
    )

    sudo pacman -S --needed --noconfirm "${packages[@]}" || {
        __rayrc_log_warn "failed to install niri packages"
        return 8
    }

    # よく使われるNerd Fontのインストール（例: Hack, FiraCode, あるいはシンボルのみ）
    sudo pacman -S --needed --noconfirm ttf-hack-nerd ttf-firacode-nerd ttf-nerd-fonts-symbols
    # fontconfigのキャッシュを強制的に再構築（重要）
    fc-cache -fv


}

__rayrc_install
unset -f __rayrc_install
