#!/usr/bin/env bash

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

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

if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
    printf '\033[2m | \033[0m\033[35m%s\033[0m \033[2m\033[33mCHANGES\033[0m' "$branch"
  else
    printf '\033[2m | \033[0m\033[35m%s\033[0m \033[2m\033[32mCLEAN\033[0m' "$branch"
  fi
else
  printf '\033[2m | No git\033[0m'
fi
