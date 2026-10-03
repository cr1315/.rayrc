#!/usr/bin/env bash

command -v kubectl >/dev/null 2>&1 || { return; }

# setup auto_completion
source /usr/share/bash-completion/bash_completion

alias k="kubectl"
complete -F __start_kubectl k

k.conf() {
    local clusters
    local cluster
    local filter
    local rc

    # TODO: usage()

    clusters=$(aws eks list-clusters 2>/dev/null)
    rc=$?
    if [[ $rc != 0 ]]; then
        echo "you're assumed to be iac for calling this method."
        aws.iac
        rc=$?
        if [[ $rc != 0 ]]; then
            return $rc
        fi
    fi

    # TODO: getopts
    filter="$1"
    clusters=$(aws eks list-clusters | jq -r '.clusters[]' | sort)
    if [[ -n $filter ]]; then
        clusters=$(echo "$clusters" | grep "$filter")
    fi
    cluster=$(echo "$clusters" | fzf --no-preview)
    if [[ -n "$cluster" ]]; then
        rm -f ~/.kube/config
        aws eks update-kubeconfig --name "$cluster"
    fi
}
