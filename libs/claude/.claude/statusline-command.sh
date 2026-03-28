#!/usr/bin/env bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
basename_cwd=$(basename "$cwd")
printf "[%s@%s %s]" "$(whoami)" "$(hostname -s)" "$basename_cwd"
