#!/usr/bin/env zsh

# Home Assistant APIを叩くための高機能ラッパー関数
ha_api() {
    # 引数が2つ未満の場合は使い方を表示して終了
    if [ "$#" -lt 2 ]; then
        echo "Usage: ha_api <METHOD> <PATH> [JSON_DATA]"
        echo "  ex) ha_api GET states/sun.sun"
        echo "  ex) ha_api POST services/light/turn_on '{\"entity_id\":\"light.living_room\"}'"
        return 1
    fi

    ## zsh: `path` is tied to $PATH, so it must not be used as a local name
    local method="${(U)1}"
    local api_path="$2"
    local data="$3"

    curl -s -X "$method" -H "Content-Type: application/json" -H "Authorization: Bearer $HASS_TOKEN" "${HASS_SERVER}/api/${api_path}" -d "$data"
}
