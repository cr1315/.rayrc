#!/usr/bin/env bash

command -v ha >/dev/null 2>&1 || { return; }

# # Home Assistant APIを叩くための高機能ラッパー関数
# ha_api() {
#   # 引数が2つ未満の場合は使い方を表示して終了
#   if [ "$#" -lt 2 ]; then
#     echo "Usage: ha_api <METHOD> <PATH> [JSON_DATA]"
#     echo "  ex) ha_api GET /api/states/sun.sun"
#     echo "  ex) ha_api POST /api/services/light/turn_on '{\"entity_id\":\"light.living_room\"}'"
#     return 1
#   fi

#   local method=$(echo "$1" | tr 'a-z' 'A-Z') # メソッドを大文字に変換
#   local path="$2"
#   local data="$3"
#   local base_url="http://supervisor/core"

#   # curlコマンドの本体（設定ファイルは引き続き利用）
#   local curl_cmd="curl --config ~/.curlrc-ha"

#   # メソッドに応じて処理を分岐
#   if [ "$method" = "POST" ]; then
#     # POSTの場合はデータ（$3）を付けて実行
#     $curl_cmd -X POST -d "$data" "${base_url}${path}"
#   else
#     # GETやその他のメソッドの場合はそのまま実行
#     $curl_cmd -X "$method" "${base_url}${path}"
#   fi | jq . # 結果をjqで見やすく整形して出力
# }

__rayrc_main() {
    __rayrc_module_common_setup

}

__rayrc_main
unset -f __rayrc_main
