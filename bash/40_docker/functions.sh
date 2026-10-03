#!/usr/bin/env bash

d.roots() {
    local cids=$(docker ps -q)
    [ -z "$cids" ] && { echo "No running containers."; return 0; }

    local tpl=""
    tpl+='{{ slice .Name 1 }}|'
    tpl+='{{ if index .Config.Labels "com.docker.compose.project.working_dir" }}'
    tpl+='{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'
    tpl+='{{ else }}'
    tpl+='<Standalone / Non-Compose>'
    tpl+='{{ end }}'

    # ｛ ｝でくくり、ヘッダーとデータの全ストリームを統合してから column に渡す
    {
        echo "CONTAINER NAME|COMPOSE WORKING DIR"
        echo "--------------|-------------------"
        docker inspect --format "$tpl" $cids
    } | column -t -s '|'
}
