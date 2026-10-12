# Git hooks armed from the Intent's gitHooks, driven through the Target's installed Apply.

SUGGESTION_LINE='drift target: run /apply-claude-config to converge'
LINK='../../.claude/scripts/git-hooks/commit-msg'
FOREIGN_REFUSAL='commit-msg not armed: .git/hooks/commit-msg is a foreign hook Apply won'"'"'t touch'

# hooks_target <intent-json> — installed Target converged to a default Intent, then
# given that Intent (not yet applied): only git-hooks can differ from converged.
hooks_target() {
  make_target
  install_target
  set_intent '{}'
  run "$APPLY"
  assert_status 0
  set_intent "$1"
}

set_intent() {
  printf '%s\n' "$1" > "$TARGET/.claude/claude-config.json"
}

test_git_hooks_enable_script_gone_from_payload() {
  make_target
  install_target
  [ -f "$TARGET/.claude/scripts/git-hooks/commit-msg" ] || fail "commit-msg hook not installed"
  [ ! -e "$TARGET/.claude/scripts/git-hooks/enable" ] || fail "enable script still installed"
  ! grep -Fxq scripts/git-hooks/enable "$TARGET/.claude/.claude-config-manifest" \
    || fail "enable script still in Manifest"
}

test_git_hooks_arm_then_rerun_is_noop() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "done git-hooks: commit-msg armed in .git/hooks"
  [ -L "$TARGET/.git/hooks/commit-msg" ] || fail "hook not symlinked"
  assert_eq "$LINK" "$(readlink "$TARGET/.git/hooks/commit-msg")" "link target"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "skipped git-hooks: commit-msg already armed"
  assert_unchanged "$before" "$TARGET"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_git_hooks_armed_hook_runs_on_commit() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  assert_status 0
  git -C "$TARGET" -c user.name=t -c user.email=t@example.com \
    commit -q --allow-empty -m $'subject\n\nCo-Authored-By: x <x@example.com>'
  ! git -C "$TARGET" log -1 --format=%B | grep -qi '^co-authored-by:' || fail "hook did not run"
}

test_git_hooks_respects_core_hooks_path() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  git -C "$TARGET" config core.hooksPath .githooks
  run "$APPLY"
  assert_status 0
  assert_line "done git-hooks: commit-msg armed in .githooks"
  assert_eq ../.claude/scripts/git-hooks/commit-msg "$(readlink "$TARGET/.githooks/commit-msg")" "link target"
  [ ! -e "$TARGET/.git/hooks/commit-msg" ] || fail "armed in .git/hooks despite core.hooksPath"
}

test_git_hooks_absent_key_reports_none() {
  hooks_target '{}'
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line "skipped git-hooks: none in Intent"
  assert_unchanged "$before" "$TARGET"
}

test_git_hooks_drop_removes_suite_link() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  assert_status 0
  set_intent '{"gitHooks": []}'
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "done git-hooks: commit-msg disarmed (not in Intent)"
  [ ! -e "$TARGET/.git/hooks/commit-msg" ] && [ ! -L "$TARGET/.git/hooks/commit-msg" ] \
    || fail "suite link not removed"
  # Absent key behaves like an empty list.
  run "$APPLY"
  set_intent '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  set_intent '{}'
  run "$APPLY"
  assert_status 0
  assert_line "done git-hooks: commit-msg disarmed (not in Intent)"
}

# An absolute link into the Payload (the old enable script's output) is the suite's.
test_git_hooks_absolute_suite_link_relinked() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  ln -s "$TARGET/.claude/scripts/git-hooks/commit-msg" "$TARGET/.git/hooks/commit-msg"
  run "$APPLY" --check
  assert_status 2
  assert_line "drift git-hooks: commit-msg in .git/hooks is not the expected relative link"
  run "$APPLY"
  assert_status 0
  assert_line "done git-hooks: commit-msg re-linked relatively in .git/hooks"
  assert_eq "$LINK" "$(readlink "$TARGET/.git/hooks/commit-msg")" "link target"
}

test_git_hooks_foreign_file_refused_untouched() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  printf '#!/bin/sh\necho own\n' > "$TARGET/.git/hooks/commit-msg"
  chmod +x "$TARGET/.git/hooks/commit-msg"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "skipped git-hooks: $FOREIGN_REFUSAL; move it aside to arm the suite's"
  assert_unchanged "$before" "$TARGET"
  run "$APPLY" --check
  assert_status 2
  assert_line "drift git-hooks: $FOREIGN_REFUSAL; move it aside, then run /apply-claude-config"
  ! grep -Fxq "$SUGGESTION_LINE" <<<"$output" || fail "suggested Apply for drift it can't cure"
  # Dropped from the Intent: still never touched.
  set_intent '{}'
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line "skipped git-hooks: commit-msg not in Intent; .git/hooks/commit-msg is a foreign hook, left untouched"
  assert_unchanged "$before" "$TARGET"
  run "$APPLY" --check
  assert_status 0
}

test_git_hooks_foreign_symlink_refused_untouched() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  mkdir -p "$TEST_TMP/elsewhere"
  printf '#!/bin/sh\n' > "$TEST_TMP/elsewhere/commit-msg"
  ln -s "$TEST_TMP/elsewhere/commit-msg" "$TARGET/.git/hooks/commit-msg"
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line "skipped git-hooks: $FOREIGN_REFUSAL; move it aside to arm the suite's"
  assert_unchanged "$before" "$TARGET"
  set_intent '{}'
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_unchanged "$before" "$TARGET"
  # A dangling foreign link is foreign too.
  rm "$TEST_TMP/elsewhere/commit-msg"
  set_intent '{"gitHooks": ["commit-msg"]}'
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 0
  assert_line "skipped git-hooks: $FOREIGN_REFUSAL; move it aside to arm the suite's"
  assert_unchanged "$before" "$TARGET"
}

# Host and Sandbox see the same tree at different absolute paths.
test_git_hooks_link_resolves_after_remount() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  assert_status 0
  moved="$TEST_TMP/mounted-elsewhere"
  mv "$TARGET" "$moved"
  assert_eq "$(cd "$moved" && pwd -P)/.claude/scripts/git-hooks/commit-msg" \
    "$(readlink -f "$moved/.git/hooks/commit-msg")" "resolved hook"
  before="$(snapshot "$moved")"
  run "$moved/.claude/scripts/apply" --check
  assert_status 0
  assert_line_count 0
  run "$moved/.claude/scripts/apply"
  assert_status 0
  assert_line "skipped git-hooks: commit-msg already armed"
  assert_unchanged "$before" "$moved"
}

test_git_hooks_check_detects_missing() {
  hooks_target '{}'
  run "$APPLY"
  assert_status 0
  set_intent '{"gitHooks": ["commit-msg"]}'
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line "drift git-hooks: commit-msg not armed in .git/hooks"
  assert_line "$SUGGESTION_LINE"
  assert_unchanged "$before" "$TARGET"
}

test_git_hooks_check_detects_surplus() {
  hooks_target '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  assert_status 0
  set_intent '{}'
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line "drift git-hooks: commit-msg armed but not in Intent"
  assert_line "$SUGGESTION_LINE"
  assert_unchanged "$before" "$TARGET"
}

test_git_hooks_unknown_hook_fails_without_writing() {
  hooks_target '{"gitHooks": ["commit-msg", "pre-nothing"]}'
  before="$(snapshot "$TARGET")"
  run "$APPLY"
  assert_status 1
  [[ "$stderr" == *pre-nothing* ]] || fail "error does not name the hook: '$stderr'"
  assert_unchanged "$before" "$TARGET"
  run "$APPLY" --check
  assert_status 1
}

test_git_hooks_invalid_key_fails() {
  for intent in '{"gitHooks": "commit-msg"}' '{"gitHooks": ["../x"]}' '{"gitHooks": [1]}'; do
    hooks_target "$intent"
    run "$APPLY"
    assert_status 1
    [[ "$stderr" == Error:* ]] || fail "expected an Error for $intent, got '$stderr'"
    rm -rf "$TARGET"
  done
}

test_git_hooks_outside_git_repo() {
  make_target
  install_target
  rm -rf "$TARGET/.git"
  set_intent '{}'
  run "$APPLY"
  assert_status 0
  assert_line "skipped git-hooks: none in Intent"
  set_intent '{"gitHooks": ["commit-msg"]}'
  run "$APPLY"
  assert_status 1
  [[ "$stderr" == *"not a git repository"* ]] || fail "unexpected error '$stderr'"
}
