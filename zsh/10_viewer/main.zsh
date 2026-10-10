#!/usr/bin/env zsh

__rayrc_main() {
    __rayrc_module_common_setup
    __rayrc_source_facade main
}

__rayrc_main
## sub modules define & unset the same name; unlike bash, zsh warns if it's already gone
unset -f __rayrc_main 2>/dev/null
