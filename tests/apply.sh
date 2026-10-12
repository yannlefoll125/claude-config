# Apply, driven through the Target's installed copy.

NO_INTENT_LINE='skipped intent: no .claude/claude-config.json; run /setup-claude-config to create it'

test_install_ships_apply() {
  make_target
  install_target
  [ -x "$APPLY" ] || fail "installed Apply missing or not executable"
  grep -Fxq scripts/apply "$TARGET/.claude/.claude-config-manifest" || fail "Apply not in Manifest"
}

test_no_intent_is_noop_with_pointer() {
  make_target
  install_target
  stub claude
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line "$NO_INTENT_LINE"
  assert_line_count 1
  assert_report
  assert_unchanged "$before" "$TARGET"
  assert_eq "" "$(stub_calls claude)" "claude calls"
}

test_resolves_target_from_any_cwd() {
  make_target
  install_target
  mkdir -p "$TARGET/sub/dir"
  run bash -c 'cd "$1" && "$2"' _ "$TARGET/sub/dir" "$APPLY"
  assert_status 0
  assert_line "$NO_INTENT_LINE"
  run bash -c 'cd / && "$1"' _ "$APPLY"
  assert_status 0
  assert_line "$NO_INTENT_LINE"
  # Relative invocation, as an in-session agent would run it.
  run bash -c 'cd "$1" && .claude/scripts/apply' _ "$TARGET"
  assert_status 0
  assert_line "$NO_INTENT_LINE"
}

# Host and Sandbox see the same tree at different absolute paths.
test_works_after_remount_at_other_path() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  mv "$TARGET" "$TEST_TMP/mounted-elsewhere"
  before="$(snapshot "$TEST_TMP/mounted-elsewhere")"
  run "$TEST_TMP/mounted-elsewhere/.claude/scripts/apply"
  assert_status 0
  assert_report
  assert_unchanged "$before" "$TEST_TMP/mounted-elsewhere"
  ! grep -rqF "$TEST_TMP" "$TEST_TMP/mounted-elsewhere/.claude" || fail "absolute path persisted"
}

test_intent_present_succeeds() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  assert_report
}

test_invalid_intent_fails() {
  make_target
  install_target
  echo 'not json' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  [ "$status" -ne 0 ] || fail "expected nonzero exit on invalid Intent"
  [ -n "$stderr" ] || fail "expected an error on stderr"
}

test_broken_jq_fails() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  stub jq 'exit 3'
  run "$APPLY"
  [ "$status" -ne 0 ] || fail "expected nonzero exit when jq fails"
  [ -n "$(stub_calls jq)" ] || fail "stubbed jq was not invoked"
}

test_rejects_arguments() {
  make_target
  install_target
  run "$APPLY" --bogus
  assert_status 1
  [ -z "$output" ] || fail "usage error must not print report lines"
}

test_refuses_outside_target() {
  run "$REPO/scripts/apply"
  assert_status 1
  [[ "$stderr" == Error:* ]] || fail "expected an Error on stderr, got '$stderr'"
}
