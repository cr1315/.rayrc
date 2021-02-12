#!/usr/bin/env bash

# setup function
function setup {
	if [[ -d "$RAYRC/$1" && -f "$RAYRC/$1/main.sh" ]]; then
		source "$RAYRC/$1/main.sh"
	elif [[ -f "$RAYRC/$1.sh" ]]; then
		source "$RAYRC/$1.sh"
	fi
}


### auto setup
targets=$(ls -1)











# setup bash
setup bash

# setup fzf
setup fzf

# setup kubectl
setup kubectl

# setup aws
setup aws

# setup terraform
setup terraform
