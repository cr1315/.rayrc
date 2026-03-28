#!/usr/bin/env bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
total_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Try to find git root
git_root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)

if [ -n "$git_root" ]; then
    # Inside a git repository
    repo_name=$(basename "$git_root")

    # Calculate relative path from git root to cwd
    if [ "$cwd" = "$git_root" ]; then
        rel_path="."
    else
        rel_path="${cwd#$git_root/}"
    fi

    location="${repo_name}: ${rel_path}"
else
    # Outside git repository - show full path
    location="${cwd}"
fi

# Add token usage if available
if [ -n "$total_tokens" ] && [ -n "$used_pct" ] && [ "$total_tokens" != "null" ] && [ "$used_pct" != "null" ]; then
    used_tokens=$((total_input + total_output))

    # Format numbers with K/M suffix
    if [ $used_tokens -ge 1000000 ]; then
        used_display="$((used_tokens / 1000000))M"
    elif [ $used_tokens -ge 1000 ]; then
        used_display="$((used_tokens / 1000))K"
    else
        used_display="${used_tokens}"
    fi

    if [ $total_tokens -ge 1000000 ]; then
        total_display="$((total_tokens / 1000000))M"
    elif [ $total_tokens -ge 1000 ]; then
        total_display="$((total_tokens / 1000))K"
    else
        total_display="${total_tokens}"
    fi

    token_info="${used_pct}% (${used_display}/${total_display})"

    # Get terminal width (default to 80 if not available)
    term_width=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}

    # Calculate padding needed
    token_len=${#token_info}

    printf "%-*s%*s" "$((term_width - token_len))" "$location" "$token_len" "$token_info"
else
    printf "%s" "$location"
fi
