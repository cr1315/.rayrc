#!/usr/bin/env bash

git.user() {
    local email_type
    email_type="$1"
    if [[ $email_type =~ work ]]; then
        git config --global user.email "taihang.lei@accenture.com"
    else
        git config --global user.email "584664105@qq.com"
    fi
    git config --global user.name "${USER}@$(hostname -s)"
}
