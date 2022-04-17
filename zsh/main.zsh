#!/usr/bin/env zsh

__rayrc_main() {
    local __rayrc_main_dir=$1
    # echo "\$__rayrc_main_dir: $__rayrc_main_dir"

    # prepend absolute(./00_bin) to $PATH
    if [[ ! "$PATH" == *"${__rayrc_main_dir}"/00_bin* ]]; then
        export PATH="${__rayrc_main_dir}/00_bin${PATH:+:${PATH}}"
    fi

    ### auto setup
    for dir in `ls -1 "${__rayrc_main_dir}"`; do
        # echo "\$__rayrc_main_dir/\$dir: $__rayrc_main_dir/$dir"
        if [[ -d "$__rayrc_main_dir/$dir" && -f "$__rayrc_main_dir/$dir/main.zsh" && ! -f "$__rayrc_main_dir/$dir/disabled" ]]; then
            source "$__rayrc_main_dir/$dir/main.zsh"
        fi
    done
}

__rayrc_main ${0:A:h}
unset -f __rayrc_main
