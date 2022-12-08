#!/usr/bin/env bash

__rayrc_install() {
    __rayrc_module_common_setup

    #
    # defined in ROOT/bash/install.sh as if it is global.
    # local __rayrc_bin_dir
    #

}

__rayrc_install
unset -f __rayrc_install
