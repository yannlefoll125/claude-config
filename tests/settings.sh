# Base settings converged from Intent policies: model, notifications, permission mode,
# statusline — driven through the Target's installed Apply.

SETTINGS_REL=.claude/settings.local.json
STATUS_SCRIPT=.claude/scripts/statusline.sh

# intent_target <intent-json> — installed Target with the given Intent.
intent_target() {
  make_target
  install_target
  SETTINGS="$TARGET/$SETTINGS_REL"
  printf '%s\n' "$1" > "$TARGET/.claude/claude-config.json"
}

# setting <jq-filter> — compact JSON of a filter over the Target's settings.
setting() {
  jq -c "$1" "$SETTINGS"
}

virtualised_stub() { stub systemd-detect-virt 'echo kvm'; }
bare_metal_stub() { stub systemd-detect-virt 'echo none; exit 1'; }

ALL_ON='{"model": "claude-fable-5", "notifications": false, "permissionMode": "auto-if-virtualised", "statusline": true}'

test_settings_all_policies_converge() {
  intent_target "$ALL_ON"
  virtualised_stub
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "done model: set to claude-fable-5"
  assert_line 'done notifications: disabled (preferredNotifChannel "notifications_disabled")'
  assert_line "done permission-mode: defaultMode set to auto (Intent policy auto-if-virtualised)"
  assert_line "done statusline: render-time command for .claude/scripts/statusline.sh set"
  assert_eq '"claude-fable-5"' "$(setting .model)" model
  assert_eq '"notifications_disabled"' "$(setting .preferredNotifChannel)" notifications
  assert_eq '"auto"' "$(setting .permissions.defaultMode)" defaultMode
  assert_eq '"command"' "$(setting .statusLine.type)" "statusLine type"
}

test_settings_defaults_write_only_hook() {
  intent_target '{}'
  virtualised_stub
  run "$APPLY"
  assert_status 0
  assert_line "skipped model: absent from Intent"
  assert_line "skipped notifications: already enabled"
  assert_line "skipped permission-mode: defaultMode unset (Intent policy default)"
  assert_line "skipped statusline: disabled in Intent"
  assert_eq '["hooks"]' "$(setting 'keys')" "settings keys"
  # The default policy never consults the gate.
  assert_eq "" "$(stub_calls systemd-detect-virt)" "detector calls"
}

test_settings_absent_owned_keys_removed() {
  intent_target "$ALL_ON"
  virtualised_stub
  run "$APPLY"
  assert_status 0
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line 'done model: removed "claude-fable-5" (absent from Intent)'
  assert_line 'done notifications: enabled (preferredNotifChannel "notifications_disabled" removed)'
  assert_line 'done permission-mode: defaultMode "auto" removed (Intent policy default)'
  assert_line "done statusline: statusLine removed (disabled in Intent)"
  assert_eq '["hooks"]' "$(setting 'keys')" "settings keys"
}

test_settings_foreign_keys_survive() {
  intent_target '{"statusline": true}'
  cat > "$SETTINGS" <<'EOF'
{
  "model": "claude-sonnet-x",
  "preferredNotifChannel": "terminal_bell",
  "foreign": {"keep": [1, 2.50, "x"], "nested": {"a": null}},
  "permissions": {"allow": ["Bash(ls:*)"], "defaultMode": "acceptEdits"},
  "statusLine": {"type": "command", "command": "bash /abs/old/statusline.sh"},
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "echo foreign-start"}]}],
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "echo foreign-pre"}]}]
  }
}
EOF
  foreign_before="$(setting '.foreign')"
  hooks_before="$(setting '.hooks')"
  run "$APPLY"
  assert_status 0
  assert_eq "$foreign_before" "$(setting '.foreign')" "foreign key"
  assert_eq '{"allow":["Bash(ls:*)"]}' "$(setting '.permissions')" "foreign permissions"
  assert_eq "$(jq -c '.PreToolUse' <<<"$hooks_before")" "$(setting '.hooks.PreToolUse')" "foreign hook"
  assert_eq "$(jq -c '.SessionStart[0]' <<<"$hooks_before")" "$(setting '.hooks.SessionStart[0]')" "foreign SessionStart hook"
  assert_eq 2 "$(setting '.hooks.SessionStart | length')" "SessionStart entries"
  assert_eq null "$(setting '.model')" model
  assert_eq null "$(setting '.preferredNotifChannel')" notifications
  # A foreign statusLine is an owned key: replaced by the render-time command.
  [ "$(setting '.statusLine.command')" != '"bash /abs/old/statusline.sh"' ] || fail "statusLine not converged"
}

test_settings_gate_virtualised_writes_auto() {
  intent_target '{"permissionMode": "auto-if-virtualised"}'
  virtualised_stub
  run "$APPLY"
  assert_status 0
  assert_line "done permission-mode: defaultMode set to auto (Intent policy auto-if-virtualised)"
  assert_eq '"auto"' "$(setting .permissions.defaultMode)" defaultMode
  [ -n "$(stub_calls systemd-detect-virt)" ] || fail "detector not consulted"
}

test_settings_gate_bare_metal_leaves_unset() {
  intent_target '{"permissionMode": "auto-if-virtualised"}'
  bare_metal_stub
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "skipped permission-mode: not virtualised; defaultMode left unset (Intent policy auto-if-virtualised)"
  assert_eq null "$(setting .permissions.defaultMode)" defaultMode
  # Nothing converge could cure: check stays silent.
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_settings_gate_bare_metal_leaves_existing_value() {
  intent_target '{"permissionMode": "auto-if-virtualised"}'
  echo '{"permissions": {"defaultMode": "acceptEdits"}}' > "$SETTINGS"
  bare_metal_stub
  run "$APPLY"
  assert_status 0
  assert_line 'skipped permission-mode: not virtualised; defaultMode left "acceptEdits" (Intent policy auto-if-virtualised)'
  assert_eq '"acceptEdits"' "$(setting .permissions.defaultMode)" defaultMode
}

# Host and Sandbox share settings.local.json: a Host run never strips Sandbox auto mode.
test_settings_gate_monotone_across_environments() {
  intent_target '{"permissionMode": "auto-if-virtualised"}'
  virtualised_stub
  run "$APPLY"
  assert_status 0
  assert_eq '"auto"' "$(setting .permissions.defaultMode)" "after virtualised run"
  bare_metal_stub
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line 'skipped permission-mode: not virtualised; defaultMode left "auto" (Intent policy auto-if-virtualised)'
  assert_unchanged "$before" "$TARGET"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_settings_permission_auto_is_unconditional() {
  intent_target '{"permissionMode": "auto"}'
  bare_metal_stub
  run "$APPLY"
  assert_status 0
  assert_line "done permission-mode: defaultMode set to auto (Intent policy auto)"
  assert_eq '"auto"' "$(setting .permissions.defaultMode)" defaultMode
}

test_settings_invalid_policies_fail() {
  local intent
  for intent in '{"permissionMode": "sometimes"}' '{"model": 5}' '{"model": ""}' \
    '{"notifications": "off"}' '{"statusline": "yes"}'; do
    intent_target "$intent"
    run "$APPLY"
    assert_status 1
    [ -n "$stderr" ] || fail "expected an error on stderr for $intent"
    rm -rf "$TARGET"
  done
}

# run_statusline <mount> — run the persisted statusLine command from an unrelated cwd,
# fed mock stdin JSON naming <mount> as the project dir.
run_statusline() {
  local cmd
  cmd="$(jq -r .statusLine.command "$1/$SETTINGS_REL")"
  run bash -c 'cd / && printf "%s" "$2" | sh -c "$1"' _ "$cmd" \
    "$(jq -cn --arg d "$1" '{workspace: {project_dir: $d, current_dir: $d}, model: {display_name: "M"}}')"
}

# Dummy statusline: names its own mount and echoes the project dir it was fed.
dummy_statusline() { # dummy_statusline <mount> <label>
  printf '#!/usr/bin/env bash\necho "%s $(jq -r .workspace.project_dir)"\n' "$2" > "$1/$STATUS_SCRIPT"
}

test_settings_statusline_resolves_at_render_time() {
  intent_target '{"statusline": true}'
  run "$APPLY"
  assert_status 0
  cmd="$(setting .statusLine.command)"
  ! grep -qF "$TEST_TMP" <<<"$cmd" || fail "absolute path persisted: $cmd"
  ! grep -qE "(^|[ \"'=(])/[A-Za-z0-9._~-]" <<<"$(jq -r . <<<"$cmd")" || fail "command holds an absolute path: $cmd"
  # The same tree, as the Host and a Sandbox mount it at two different paths.
  host="$TEST_TMP/host/project"
  sandbox="$TEST_TMP/sandbox/workspaces/project"
  mkdir -p "$host" "$sandbox"
  cp -a "$TARGET/." "$host"
  cp -a "$TARGET/." "$sandbox"
  dummy_statusline "$host" host-script
  dummy_statusline "$sandbox" sandbox-script
  run_statusline "$host"
  assert_status 0
  assert_eq "host-script $host" "$output" "host render"
  run_statusline "$sandbox"
  assert_status 0
  assert_eq "sandbox-script $sandbox" "$output" "sandbox render"
}

test_settings_statusline_runs_deployed_script() {
  intent_target '{"statusline": true}'
  run "$APPLY"
  assert_status 0
  run_statusline "$TARGET"
  assert_status 0
  [[ "$output" == *M* ]] || fail "deployed statusline output missing model name: $output"
}

test_settings_second_run_is_noop() {
  intent_target "$ALL_ON"
  virtualised_stub
  run "$APPLY"
  assert_status 0
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_report
  if grep -q '^done ' <<<"$output"; then fail "second run reported done lines:"$'\n'"$output"; fi
  assert_unchanged "$before" "$TARGET"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_settings_check_reports_each_owned_key() {
  intent_target "$ALL_ON"
  virtualised_stub
  run "$APPLY"
  assert_status 0
  # Hand-edit every owned key away from the Intent.
  jq '.model = "other" | .preferredNotifChannel = "terminal_bell"
      | .permissions.defaultMode = "plan" | .statusLine.command = "bash /abs/statusline.sh"' \
    "$SETTINGS" > "$SETTINGS.new" && mv "$SETTINGS.new" "$SETTINGS"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line 'drift model: is "other", Intent wants "claude-fable-5"'
  assert_line 'drift notifications: preferredNotifChannel is "terminal_bell", Intent wants "notifications_disabled"'
  assert_line 'drift permission-mode: defaultMode is "plan", Intent policy auto-if-virtualised wants "auto" here'
  assert_line "drift statusline: statusLine differs from the render-time command"
  assert_line "drift target: run /apply-claude-config to converge"
  assert_unchanged "$before" "$TARGET"
  run "$APPLY"
  assert_status 0
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_settings_check_reports_unowned_by_intent() {
  intent_target '{}'
  echo '{"model": "m", "preferredNotifChannel": "terminal_bell", "permissions": {"defaultMode": "auto"}, "statusLine": {"type": "command", "command": "x"}}' > "$SETTINGS"
  run "$APPLY" --check
  assert_status 2
  assert_line 'drift model: is "m" but absent from Intent'
  assert_line 'drift notifications: preferredNotifChannel is "terminal_bell" but Intent leaves notifications on'
  assert_line 'drift permission-mode: defaultMode is "auto" but Intent policy is default'
  assert_line "drift statusline: statusLine present but disabled in Intent"
}

test_settings_check_missing_keys() {
  intent_target "$ALL_ON"
  virtualised_stub
  run "$APPLY" --check
  assert_status 2
  assert_line 'drift model: is unset, Intent wants "claude-fable-5"'
  assert_line 'drift notifications: preferredNotifChannel is unset, Intent wants "notifications_disabled"'
  assert_line 'drift permission-mode: defaultMode is unset, Intent policy auto-if-virtualised wants "auto" here'
  assert_line "drift statusline: statusLine missing from .claude/settings.local.json"
}
