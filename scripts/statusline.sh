#!/usr/bin/env bash

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
style=$(echo "$input" | jq -r '.output_style.name // empty')

[ -n "$style" ] && [ "$style" != "default" ] && model="$model ($style)"

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
  project=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
    printf '\033[2m | \033[0m%s \033[2m(\033[0m\033[35m%s\033[0m \033[33mCHANGES\033[0m\033[2m)\033[0m' "$project" "$branch"
  else
    printf '\033[2m | \033[0m%s \033[2m(\033[0m\033[35m%s\033[0m \033[32mCLEAN\033[0m\033[2m)\033[0m' "$project" "$branch"
  fi
else
  printf '\033[2m | No git\033[0m'
fi

acct=$(jq -r '.oauthAccount | [.emailAddress // "", .organizationType // "", .userRateLimitTier // ""] | @tsv' "$HOME/.claude.json" 2>/dev/null)
IFS=$'\t' read -r email org_type user_tier <<<"$acct"

# Env-based auth overrides the oauth subscription as the active vector.
if [ -n "${CLAUDE_CODE_USE_BEDROCK:-}" ]; then
  vector="Bedrock"
elif [ -n "${CLAUDE_CODE_USE_VERTEX:-}" ]; then
  vector="Vertex"
elif [ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
  vector="auth token"
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  vector="API key …${ANTHROPIC_API_KEY: -4}"
elif [ -n "$email" ]; then
  case "$user_tier" in
    *max_5x*) tier="Max 5x" price='$100/mo' ;;
    *max_20x*) tier="Max 20x" price='$200/mo' ;;
    *claude_pro*) tier="Pro" price="" ;;
    *) tier="" price="" ;;
  esac
  # Seat pricing in team/enterprise orgs differs from individual plans,
  # and enterprise contracts aren't in ~/.claude.json — tier label only.
  case "$org_type" in
    claude_team) vector="Team${tier:+ $tier}" ;;
    claude_enterprise) vector="Enterprise${tier:+ $tier}" ;;
    *) vector="${tier:-Subscription}${price:+ $price}" ;;
  esac
else
  vector=""
fi

if [ -n "$email" ]; then
  login="$email${vector:+ ($vector)}"
else
  login="$vector"
fi
[ -n "$login" ] && printf '\033[2m | %s\033[0m' "$login"
