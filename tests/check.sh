# Apply's read-only check mode (--check), driven through the Target's installed copy.

NO_INTENT_LINE='skipped intent: no .claude/claude-config.json; run /setup-claude-config to create it'
SUGGESTION_LINE='drift target: run /apply-claude-config to converge'

# converged_target — installed Target with a default Intent, Apply already run.
converged_target() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
}

# The skill the suggestion names ships with the Payload.
test_check_suggested_skill_is_installed() {
  make_target
  install_target
  skill="$(sed 's|.* run /\([a-z0-9-]*\) .*|\1|' <<<"$SUGGESTION_LINE")"
  [ -f "$TARGET/.claude/skills/$skill/SKILL.md" ] || fail "suggested skill $skill not installed"
}

test_check_clean_is_silent() {
  converged_target
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
  assert_unchanged "$before" "$TARGET"
}

test_check_no_intent_exit_and_pointer_only() {
  make_target
  install_target
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 3
  assert_line "$NO_INTENT_LINE"
  assert_line_count 1
  assert_unchanged "$before" "$TARGET"
}

test_check_drift_names_skill_and_writes_nothing() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line "drift staleness-hook: SessionStart check missing from .claude/settings.local.json"
  assert_line "$SUGGESTION_LINE"
  assert_unchanged "$before" "$TARGET"
}

test_check_drift_when_hook_disabled_but_present() {
  converged_target
  echo '{"stalenessHook": false}' > "$TARGET/.claude/claude-config.json"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_line "drift staleness-hook: SessionStart check present but disabled in Intent"
  assert_line "$SUGGESTION_LINE"
  assert_unchanged "$before" "$TARGET"
}

test_check_converged_by_apply() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY" --check
  assert_status 2
  run "$APPLY"
  assert_status 0
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_check_detects_modified_payload_file() {
  converged_target
  echo '# local edit' >> "$TARGET/.claude/scripts/statusline.sh"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_report
  grep -q '^drift payload: .*claude-config-install' <<<"$output" || fail "no payload drift line in: $output"
  # Re-installing cures it; converging can't, so no skill suggestion.
  if grep -Fxq "$SUGGESTION_LINE" <<<"$output"; then fail "payload-only drift must not suggest the skill"; fi
  assert_unchanged "$before" "$TARGET"
}

test_check_detects_missing_payload_file() {
  converged_target
  rm "$TARGET/.claude/scripts/statusline.sh"
  run "$APPLY" --check
  assert_status 2
  grep -q '^drift payload: ' <<<"$output" || fail "no payload drift line in: $output"
}

test_check_reinstall_cures_payload_drift() {
  converged_target
  echo '# local edit' >> "$TARGET/.claude/scripts/statusline.sh"
  install_target
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_check_project_files_in_managed_dirs_ignored() {
  converged_target
  mkdir -p "$TARGET/.claude/skills/project-own"
  echo 'mine' > "$TARGET/.claude/skills/project-own/SKILL.md"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_check_invalid_intent_fails() {
  make_target
  install_target
  echo 'not json' > "$TARGET/.claude/claude-config.json"
  run "$APPLY" --check
  assert_status 1
  [ -n "$stderr" ] || fail "expected an error on stderr"
}

test_check_rejects_extra_arguments() {
  make_target
  install_target
  run "$APPLY" --check --bogus
  assert_status 1
  [ -z "$output" ] || fail "usage error must not print report lines"
}
