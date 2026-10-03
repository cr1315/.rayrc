#!/usr/bin/env bash

pacman -Syu --noconfirm

pacman -S base-devel git --noconfirm





## これ本当は要らないんじゃない、、？環境変数あれば一発で出来た？
pacman -S --needed vulkan-dzn vulkan-icd-loader vulkan-tools --noconfirm
