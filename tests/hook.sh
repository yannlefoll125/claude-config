# The SessionStart staleness hook: a settings key Apply converges from the Intent.

HOOK_CMD='"$CLAUDE_PROJECT_DIR"/.claude/scripts/apply --check || true'

settings() { echo "$TARGET/.claude/settings.local.json"; }

# hook_count — how many SessionStart hooks run the check command.
hook_count() {
  jq --arg cmd "$HOOK_CMD" '[.hooks.SessionStart[]?.hooks[]? | select(.command == $cmd)] | length' "$(settings)"
}

test_hook_on_by_default() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "done staleness-hook: SessionStart check added to .claude/settings.local.json"
  assert_eq 1 "$(hook_count)" "hook entries"
}

test_hook_explicit_on() {
  make_target
  install_target
  echo '{"stalenessHook": true}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_eq 1 "$(hook_count)" "hook entries"
}

test_hook_second_run_is_noop() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line "skipped staleness-hook: already in place"
  assert_unchanged "$before" "$TARGET"
}

test_hook_disabled_removes_entry() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  echo '{"stalenessHook": false}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_line "done staleness-hook: SessionStart check removed (disabled in Intent)"
  assert_eq '{}' "$(jq -c . "$(settings)")" "settings after removal"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_line "skipped staleness-hook: disabled in Intent"
  assert_unchanged "$before" "$TARGET"
}

test_hook_disabled_without_settings_creates_nothing() {
  make_target
  install_target
  echo '{"stalenessHook": false}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  [ ! -e "$(settings)" ] || fail "settings file created for a disabled hook"
}

test_hook_invalid_intent_value_fails() {
  make_target
  install_target
  echo '{"stalenessHook": "yes"}' > "$TARGET/.claude/claude-config.json"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 1
  [[ "$stderr" == *stalenessHook* ]] || fail "error should name the key, got '$stderr'"
  assert_unchanged "$before" "$TARGET"
}

FOREIGN='{
  "theme": "dark",
  "permissions": {"allow": ["Bash(ls)"]},
  "hooks": {
    "SessionStart": [{"matcher": "startup", "hooks": [{"type": "command", "command": "echo hi"}]}],
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "true"}]}]
  }
}'

# Everything but the owned hook entry, normalised.
foreign_view() {
  jq -S --arg cmd "$HOOK_CMD" '
    .hooks.SessionStart |= map(.hooks |= map(select(.command != $cmd)) | select(.hooks | length > 0))' "$(settings)"
}

test_hook_foreign_settings_survive_add_and_remove() {
  make_target
  install_target
  printf '%s\n' "$FOREIGN" > "$(settings)"
  expected="$(jq -S . "$(settings)")"
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_eq 1 "$(hook_count)" "hook entries"
  assert_eq "$expected" "$(foreign_view)" "foreign settings after add"
  echo '{"stalenessHook": false}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_eq 0 "$(hook_count)" "hook entries"
  assert_eq "$expected" "$(jq -S . "$(settings)")" "settings after remove"
}

test_hook_converged_file_untouched_byte_for_byte() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  # Hand-reformat the converged file; a converged run must not rewrite it.
  jq -c . "$(settings)" > "$TEST_TMP/compact" && cp "$TEST_TMP/compact" "$(settings)"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_unchanged "$before" "$TARGET"
}

test_hook_invalid_settings_fails_untouched() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  echo 'not json' > "$(settings)"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 1
  [ -n "$stderr" ] || fail "expected an error on stderr"
  assert_unchanged "$before" "$TARGET"
}

# The persisted command, run the way Claude Code runs a hook: through a shell,
# with CLAUDE_PROJECT_DIR set, from an arbitrary cwd.
run_hook() {
  local cmd
  cmd="$(jq -r --arg cmd "$HOOK_CMD" '.hooks.SessionStart[].hooks[] | select(.command == $cmd) | .command' "$(settings)")"
  run env CLAUDE_PROJECT_DIR="$1" bash -c "cd / && $cmd"
}

test_hook_command_silent_on_clean_target() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  run_hook "$TARGET"
  assert_status 0
  assert_line_count 0
}

test_hook_command_surfaces_suggestion_on_drift() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  echo '{"stalenessHook": false}' > "$TARGET/.claude/claude-config.json"
  before="$(snapshot "$TARGET")"
  run_hook "$TARGET"
  assert_status 0
  assert_line 'drift target: run /apply-claude-config to converge'
  assert_unchanged "$before" "$TARGET"
}

test_hook_command_works_after_remount() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  mv "$TARGET" "$TEST_TMP/mounted-elsewhere"
  TARGET="$TEST_TMP/mounted-elsewhere"
  echo '# local edit' >> "$TARGET/.claude/scripts/statusline.sh"
  run_hook "$TARGET"
  assert_status 0
  grep -q '^drift payload: ' <<<"$output" || fail "no payload drift line in: $output"
}
