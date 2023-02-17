#!/usr/bin/env bash

## TODO: write my own ssh utilizing FZF
sshs() {
    local host_lists
    local search_pattern
    local ssh_command

    search_pattern="$1"
    host_lists=$(find "${HOME}/.ssh" -name '*config' -exec sh -c "grep '^Host' {} | sed -E 's/^Host //'" \;)

    if [[ ! "${search_pattern}" =~ ^[[:space:]]*$ ]]; then
        host_lists=$(echo "$host_lists" | grep -E "${search_pattern}")
    fi
    ssh_command=$(echo "$host_lists" | sed -E 's/^/ssh /' | fzf --no-preview)
    $ssh_command
}
