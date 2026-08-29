#!/usr/bin/env bash

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ "$tokens" -ge 1000 ] 2>/dev/null; then
  tokens_fmt=$(awk -v t="$tokens" 'BEGIN{printf "%.1fk", t/1000}')
else
  tokens_fmt="$tokens"
fi

if [ -n "$used_pct" ]; then
  printf '\033[2m%s | \033[0m\033[36m%s tokens\033[0m\033[2m (%.0f%% used)\033[0m' "$model" "$tokens_fmt" "$used_pct"
else
  printf '\033[2m%s | \033[0m\033[36m%s tokens\033[0m' "$model" "$tokens_fmt"
fi
