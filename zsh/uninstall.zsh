#!/usr/bin/env zsh

__rayrc_setup() {
    local __rayrc_setup_dir=$1
    # echo "\$__rayrc_main: $__rayrc_dir"

    # prepend absolute(./00_bin) to $PATH
    if [[ ! "$PATH" == *"${__rayrc_setup_dir}"/00_bin* ]]; then
        export PATH="${__rayrc_setup_dir}/00_bin${PATH:+:${PATH}}"
    fi

    ### auto setup
    for dir in $(ls -1 "${__rayrc_setup_dir}"); do
        # echo "\$__rayrc_main/\$dir: $__rayrc_dir/$dir"
        if [[ -d "$__rayrc_main/$dir" && -f "$__rayrc_setup_dir/$dir/main.zsh" && ! -f "$__rayrc_dir/$dir/disabled" ]]; then
            source "$__rayrc_setup_dir/$dir/main.zsh"
        fi
    done
}

__rayrc_setup ${0:A:h}
unset -f __rayrc_setup
