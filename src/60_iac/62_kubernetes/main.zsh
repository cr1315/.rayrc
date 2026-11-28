#!/usr/bin/env zsh

command -v kubectl >/dev/null 2>&1 || { return; }

## completion needs compinit, which rayrc does not run itself.
## zsh completes the alias `k` like kubectl by itself (bash needs `complete -F __start_kubectl k`)
(( ${+functions[compdef]} )) && source <(kubectl completion zsh)

alias k="kubectl"

k.conf() {
    local clusters
    local cluster
    local filter
    local rc

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
