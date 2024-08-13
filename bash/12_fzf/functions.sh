#!/usr/bin/env bash

ssh() {
    ## save ssh bin path for subclassing
    local ssh_bin=$(/usr/bin/which ssh)

    ## shortcut
    if [[ "$#" -ge 2 ]]; then
        # echo "parameters: $@"
        $ssh_bin "$@"
        return
    fi
    if [[ "$#" -eq 1 && "$1" =~ ^- ]]; then
        # echo "parameters: $@"
        $ssh_bin "$@"
        return
    fi

    local search_pattern
    local host_lists
    local hosts_filtered
    local hosts_filtered_count
    local ssh_command

    search_pattern="$1"
    host_lists=$(find "${HOME}/.ssh" -name '*config' -exec sh -c "grep '^Host' {} | sed -E 's/^Host //'" \;)

    if [[ ! "${search_pattern}" =~ ^[[:space:]]*$ ]]; then
        hosts_filtered=$(echo "$host_lists" | grep -E "${search_pattern}")
        # echo "hosts_filtered:" "$hosts_filtered"
    else
        hosts_filtered="$host_lists"
    fi

    hosts_filtered_count=$(echo "$hosts_filtered" | wc -l)
    if [[ $hosts_filtered_count -gt 1 ]]; then
        ssh_command=$(echo "$hosts_filtered" | sed -E "s|^|ssh |" | fzf --no-preview)
    elif [[ $hosts_filtered_count -eq 1 ]]; then
        ssh_command=$(echo "$hosts_filtered" | sed -E "s|^|ssh |")
    else
        ssh_command="ssh $1"
    fi
    ssh_command=$(echo "$ssh_command" | sed -E "s|^ssh|${ssh_bin}|")
    ${ssh_command}
}
