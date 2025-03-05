#!/usr/bin/env bash

ecs.exec() {
    local cluster_name=$1
    local tasks
    tasks=$(aws ecs list-tasks --cluster "$cluster_name" | jq -r '.taskArns[]')
    aws ecs execute-command --interactive \
        --cluster $cluster_name \
        --command "/bin/bash" \
        --task $(echo $tasks | fzf --preview 'echo {}' --preview-window down:40%:wrap)
}

