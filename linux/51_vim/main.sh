#!/usr/bin/env bash

command -v vim >/dev/null 2>&1 || { return; }


__rayrc_vim_setup() {
	local __rayrc_vim_setup_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
	# echo "__rayrc_vim_setup_dir: ${__rayrc_vim_setup_dir}"

	if [[ -h "$HOME/.vim" || ! -d "$HOME/.vim" ]]; then
        # if [[  && ! "$(readlink -f ~/.vim)" = *".rayrc"* ]]; then do stuff; fi
        # echo "ln -snf"
        ln -snf "${__rayrc_vim_setup_dir}/vimfiles" "$HOME/.vim"

    # elif [[  ]]; then
    #     echo "bind mount"
    #     mkdir "$HOME/.vim"
    #     mount -o bind "${__rayrc_vim_setup_dir}/vimfiles" "$HOME/.vim"

    else
        # it's annoyed..
        # first check if it's a bind mount
        #   if not override it with a `mount -o bind`
        #   if it is, you won't like to do the same target `mount -o bind` multiple times
        #     so check the target and decide then..
        true
    fi

    # we don't need a `.vimrc`
    if [[ -f "$HOME/.vimrc" ]]; then
        mv "$HOME/.vimrc" "$HOME/.rayrc_bkup.vimrc"
    fi

}

__rayrc_vim_setup
unset -f __rayrc_vim_setup

