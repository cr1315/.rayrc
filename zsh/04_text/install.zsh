#!/usr/bin/env zsh

__rayrc_install() {
    __rayrc_module_common_setup
    __rayrc_source_facade install
}

__rayrc_install
## sub modules define & unset the same name; unlike bash, zsh warns if it's already gone
unset -f __rayrc_install 2>/dev/null
