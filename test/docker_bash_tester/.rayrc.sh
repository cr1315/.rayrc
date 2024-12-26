#!/usr/bin/env bash

cd $HOME

# apt update -y
# apt-get install -y software-properties-common

## echo "deb [trusted=yes] http://ppa.launchpad.net/jonathonf/vim/ubuntu kinetic main restricted" >>/etc/apt/sources.list
apt update -y
apt install -y tree
apt install -y vim
apt install -y eza

apt-get clean autoclean
apt-get autoremove --yes
rm -rf /var/lib/{apt,cache,log}/

git config --global credential.helper store

git clone --branch refactor_structure --single-branch --depth 1 https://github.com/cr1315/.rayrc.git && source .rayrc/install
