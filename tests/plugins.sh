# Apply's plugins concern: Intent-listed plugins installed at project scope through
# the (stubbed) claude CLI; plugins the Intent doesn't list are only reported.

PLUGIN=mattpocock-skills@claude-plugins-official
OTHER=other-plugin@some-market
SUGGESTION_LINE='drift target: run /apply-claude-config to converge'

# plugins_target <intent-json> — installed Target with that Intent and a private
# environment home (plugin cache) so nothing reaches the real ~/.claude.
plugins_target() {
  make_target
  install_target
  printf '%s\n' "$1" > "$TARGET/.claude/claude-config.json"
  unset CLAUDE_CONFIG_DIR
  export HOME="$TEST_TMP/home"
  mkdir -p "$HOME"
  PROJECT_SETTINGS="$TARGET/.claude/settings.json"
}

# stub_plugin_cli — fake claude whose "plugin install --scope project <p>" does what
# the real CLI does: enables <p> in the cwd project's .claude/settings.json and puts
# the plugin into this environment's cache.
stub_plugin_cli() {
  stub claude '
[ "$1 $2 $3 $4" = "plugin install --scope project" ] || exit 2
p="$5"; f=.claude/settings.json
[ -f "$f" ] || echo "{}" > "$f"
jq --arg p "$p" ".enabledPlugins[\$p] = true" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
mkdir -p "$HOME/.claude/plugins/cache/${p#*@}/${p%@*}/1.0.0"'
}

# enable_by_hand <plugin> — the entry another environment (or the user) left behind.
enable_by_hand() {
  [ -f "$PROJECT_SETTINGS" ] || echo '{}' > "$PROJECT_SETTINGS"
  jq --arg p "$1" '.enabledPlugins[$p] = true' "$PROJECT_SETTINGS" > "$PROJECT_SETTINGS.tmp"
  mv "$PROJECT_SETTINGS.tmp" "$PROJECT_SETTINGS"
}

cache_by_hand() { # cache_by_hand <plugin>
  mkdir -p "$HOME/.claude/plugins/cache/${1#*@}/${1%@*}/1.0.0"
}

# Hide the real claude too: PATH keeps only the fake bin and the system tools.
path_without_claude() {
  local d keep="$FAKE_BIN"
  rm -f "$FAKE_BIN/claude"
  IFS=: read -ra dirs <<<"$PATH"
  for d in "${dirs[@]}"; do
    [ "$d" = "$FAKE_BIN" ] || [ -x "$d/claude" ] || keep="$keep:$d"
  done
  export PATH="$keep"
  ! command -v claude >/dev/null || fail "claude still on PATH"
}

test_plugins_converge_installs_at_project_scope() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  stub_plugin_cli
  run "$APPLY"
  assert_status 0
  assert_report
  assert_eq "claude plugin install --scope project $PLUGIN" "$(stub_calls claude)" "claude calls"
  assert_line "done plugins: $PLUGIN enabled in .claude/settings.json (shared) and cached in this environment; each other environment caches it on its own Apply run"
  assert_eq true "$(jq -r --arg p "$PLUGIN" '.enabledPlugins[$p]' "$PROJECT_SETTINGS")" "enabledPlugins entry"
  # The rest of Apply ran too.
  assert_line "done staleness-hook: SessionStart check added to .claude/settings.local.json"
}

test_plugins_converge_installs_every_missing_plugin() {
  plugins_target "{\"plugins\": [\"$PLUGIN\", \"$OTHER\"]}"
  stub_plugin_cli
  run "$APPLY"
  assert_status 0
  assert_eq "claude plugin install --scope project $PLUGIN"$'\n'"claude plugin install --scope project $OTHER" \
    "$(stub_calls claude)" "claude calls"
}

test_plugins_already_installed_is_reported_noop() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  enable_by_hand "$PLUGIN"
  cache_by_hand "$PLUGIN"
  stub_plugin_cli
  run "$APPLY"
  assert_status 0
  assert_line "skipped plugins: $PLUGIN already enabled in .claude/settings.json and cached in this environment"
  assert_eq "" "$(stub_calls claude)" "claude calls"
}

# Split scope: the entry came with the Target, this environment's cache didn't.
test_plugins_entry_present_cache_missing_installs_here() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  enable_by_hand "$PLUGIN"
  stub_plugin_cli
  before="$(cat "$PROJECT_SETTINGS")"
  run "$APPLY"
  assert_status 0
  assert_eq "claude plugin install --scope project $PLUGIN" "$(stub_calls claude)" "claude calls"
  assert_line "done plugins: $PLUGIN cached in this environment (its entry was already in .claude/settings.json); each other environment caches it on its own Apply run"
  assert_eq "$before" "$(jq . "$PROJECT_SETTINGS")" "project settings"
}

test_plugins_idempotent() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  stub_plugin_cli
  run "$APPLY"
  assert_status 0
  : > "$STUB_LOG"
  before="$(snapshot "$TARGET")"
  home_before="$(snapshot "$HOME")"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_unchanged "$before" "$TARGET"
  assert_unchanged "$home_before" "$HOME"
  assert_eq "" "$(stub_calls claude)" "claude calls"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_plugins_cli_unavailable_skips_with_reason() {
  plugins_target "{\"plugins\": [\"$PLUGIN\", \"$OTHER\"]}"
  path_without_claude
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "skipped plugins: claude CLI not on PATH; not installed in this environment: $PLUGIN $OTHER"
  [ "$(grep -c '^[a-z]* plugins: ' <<<"$output")" -eq 1 ] || fail "expected one plugins line in: $output"
  [ ! -e "$PROJECT_SETTINGS" ] || fail "project settings written without the CLI"
  # Steps around it are unaffected.
  assert_line "done staleness-hook: SessionStart check added to .claude/settings.local.json"
}

test_plugins_cli_unavailable_but_nothing_to_do() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  enable_by_hand "$PLUGIN"
  cache_by_hand "$PLUGIN"
  path_without_claude
  run "$APPLY"
  assert_status 0
  assert_line "skipped plugins: $PLUGIN already enabled in .claude/settings.json and cached in this environment"
}

test_plugins_cli_failure_fails_apply() {
  plugins_target "{\"plugins\": [\"$PLUGIN\", \"$OTHER\"]}"
  stub claude 'exit 1'
  run "$APPLY"
  assert_status 1
  grep -qF "$PLUGIN" <<<"$stderr" || fail "failing plugin not named on stderr: $stderr"
  grep -qF "$OTHER" <<<"$stderr" || fail "second plugin not attempted: $stderr"
  [ "$(stub_calls claude | wc -l)" -eq 2 ] || fail "expected both plugins attempted"
}

# A CLI that exits 0 without enabling the plugin is a failure, not convergence.
test_plugins_cli_success_without_entry_fails() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  stub claude
  run "$APPLY"
  assert_status 1
  grep -qF "$PLUGIN" <<<"$stderr" || fail "plugin not named on stderr: $stderr"
}

test_plugins_dropped_is_report_only() {
  plugins_target '{}'
  enable_by_hand "$OTHER"
  cache_by_hand "$OTHER"
  stub_plugin_cli
  run "$APPLY" # converge the rest so only the plugin remains
  : > "$STUB_LOG"
  before="$(snapshot "$TARGET")"
  home_before="$(snapshot "$HOME")"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "skipped plugins: $OTHER enabled in .claude/settings.json but not in the Intent; Apply never uninstalls — remove it by hand (claude plugin uninstall --scope project $OTHER) or add it to the Intent"
  assert_eq "" "$(stub_calls claude)" "claude calls"
  assert_unchanged "$before" "$TARGET"
  assert_unchanged "$home_before" "$HOME"
}

test_plugins_disabled_entry_not_reported() {
  plugins_target '{}'
  echo "{\"enabledPlugins\": {\"$OTHER\": false}}" > "$PROJECT_SETTINGS"
  run "$APPLY"
  assert_status 0
  if grep -q ' plugins: ' <<<"$output"; then fail "disabled plugin reported: $output"; fi
}

test_plugins_check_reports_missing_plugin() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  stub_plugin_cli
  run "$APPLY"
  rm "$PROJECT_SETTINGS"
  before="$(snapshot "$TARGET")"
  : > "$STUB_LOG"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line "drift plugins: $PLUGIN not enabled in .claude/settings.json"
  assert_line "$SUGGESTION_LINE"
  assert_eq "" "$(stub_calls claude)" "claude calls"
  assert_unchanged "$before" "$TARGET"
}

test_plugins_check_reports_missing_cache() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  stub_plugin_cli
  run "$APPLY"
  rm -rf "$HOME/.claude/plugins/cache"
  run "$APPLY" --check
  assert_status 2
  assert_line "drift plugins: $PLUGIN enabled in .claude/settings.json but not cached in this environment"
  assert_line "$SUGGESTION_LINE"
}

test_plugins_check_without_cli_does_not_suggest_apply() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  stub_plugin_cli
  run "$APPLY"
  rm "$PROJECT_SETTINGS"
  path_without_claude
  run "$APPLY" --check
  assert_status 2
  assert_line "drift plugins: $PLUGIN not enabled in .claude/settings.json; claude CLI not on PATH, so Apply can't install it here"
  if grep -Fxq "$SUGGESTION_LINE" <<<"$output"; then fail "uncurable drift must not suggest the skill"; fi
}

test_plugins_check_reports_dropped_without_suggestion() {
  plugins_target '{}'
  run "$APPLY"
  enable_by_hand "$OTHER"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line "drift plugins: $OTHER enabled in .claude/settings.json but not in the Intent; Apply never uninstalls — remove it by hand (claude plugin uninstall --scope project $OTHER) or add it to the Intent"
  if grep -Fxq "$SUGGESTION_LINE" <<<"$output"; then fail "manual-removal drift must not suggest the skill"; fi
  assert_unchanged "$before" "$TARGET"
}

test_plugins_honours_claude_config_dir() {
  plugins_target "{\"plugins\": [\"$PLUGIN\"]}"
  enable_by_hand "$PLUGIN"
  export CLAUDE_CONFIG_DIR="$TEST_TMP/config-dir"
  mkdir -p "$CLAUDE_CONFIG_DIR/plugins/cache/${PLUGIN#*@}/${PLUGIN%@*}/1.0.0"
  stub_plugin_cli
  run "$APPLY"
  assert_status 0
  assert_line "skipped plugins: $PLUGIN already enabled in .claude/settings.json and cached in this environment"
}

test_plugins_rejects_malformed_intent() {
  plugins_target '{"plugins": ["no-marketplace"]}'
  stub_plugin_cli
  run "$APPLY"
  assert_status 1
  [ -n "$stderr" ] || fail "expected an error on stderr"
  assert_eq "" "$(stub_calls claude)" "claude calls"
  plugins_target '{"plugins": "x@y"}'
  run "$APPLY" --check
  assert_status 1
}
