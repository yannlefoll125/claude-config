# Managed Blocks: marker-wrapped, hash-stamped suite prose in a Target's tracked
# markdown. Check and converge report drift; only --refresh rewrites, and only
# between markers (or below a seed header).

REFRESH_STEP='run /apply-claude-config refresh'

sha12() { sha256sum | cut -c1-12; }

# blocks_target — installed Target with an Intent, converged, plus a test-only
# shipped block source "demo" placed beside the real ones.
blocks_target() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  run "$APPLY"
  assert_status 0
  BLOCKS="$TARGET/.claude/scripts/blocks"
  printf 'Shipped line one.\nShipped line two.\n' > "$BLOCKS/demo.md"
}

# inline_block <id> <content-file> — a stamped block whose stamp matches its content.
inline_block() {
  printf '<!-- claude-config:begin %s %s -->\n' "$1" "$(sha12 < "$2")"
  cat "$2"
  printf '<!-- claude-config:end %s -->\n' "$1"
}

# write_doc <rel> — CLAUDE.md-style file: hand prose around a current "demo" block; tracked.
write_doc() {
  {
    printf '# Project notes\n\nHand-written intro, kept as is.\n\n'
    inline_block demo "$BLOCKS/demo.md"
    printf '\nHand-written outro.\n'
  } > "$TARGET/$1"
  git -C "$TARGET" add "$1"
}

# outside <file> — the file with every marker-wrapped region removed.
outside() {
  awk '/^<!-- claude-config:begin /{skip=1; next} /^<!-- claude-config:end /{skip=0; next} !skip' "$1"
}

test_blocks_shipped_source_installed() {
  make_target
  install_target
  [ -f "$TARGET/.claude/scripts/blocks/claude-config.md" ] || fail "no shipped block source installed"
  grep -Fxq scripts/blocks/claude-config.md "$TARGET/.claude/.claude-config-manifest" \
    || fail "block source not in Manifest"
}

test_blocks_current_is_clean() {
  blocks_target
  write_doc CLAUDE.md
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "skipped managed-blocks: 1 block(s) current"
}

test_blocks_none_found() {
  blocks_target
  run "$APPLY"
  assert_status 0
  assert_line "skipped managed-blocks: no Managed Blocks in tracked markdown"
}

test_blocks_hand_edit_drift_reported_not_written() {
  blocks_target
  write_doc CLAUDE.md
  sed -i 's/Shipped line two./Edited by hand./' "$TARGET/CLAUDE.md"
  before="$(snapshot "$TARGET")"
  line="drift managed-blocks: CLAUDE.md: block demo edited inside its markers; $REFRESH_STEP to rewrite it (overwrites those edits)"
  run "$APPLY" --check
  assert_status 2
  assert_report
  assert_line "$line"
  # Converging can't cure it, so no skill-converge suggestion.
  if grep -q '^drift target:' <<<"$output"; then fail "block drift must not suggest converging"; fi
  assert_unchanged "$before" "$TARGET"
  run "$APPLY"
  assert_status 0
  assert_report
  assert_line "$line"
  assert_unchanged "$before" "$TARGET"
}

test_blocks_payload_update_drift_reported_not_written() {
  blocks_target
  write_doc CLAUDE.md
  printf 'Shipped line one, revised.\n' > "$BLOCKS/demo.md"
  before="$(snapshot "$TARGET")"
  line="drift managed-blocks: CLAUDE.md: block demo behind the Payload; $REFRESH_STEP to rewrite it"
  run "$APPLY" --check
  assert_status 2
  assert_line "$line"
  assert_unchanged "$before" "$TARGET"
  run "$APPLY"
  assert_status 0
  assert_line "$line"
  assert_unchanged "$before" "$TARGET"
}

test_blocks_refresh_step_names_shipped_skill() {
  make_target
  install_target
  skill="$(sed 's|run /\([a-z0-9-]*\) .*|\1|' <<<"$REFRESH_STEP")"
  grep -q "refresh" "$TARGET/.claude/skills/$skill/SKILL.md" || fail "skill $skill doesn't document refresh"
}

test_blocks_refresh_rewrites_only_marker_contents() {
  blocks_target
  mkdir -p "$TARGET/docs"
  write_doc docs/notes.md
  # A second block, hand-edited, plus a no-final-newline tail outside the markers.
  { inline_block demo "$BLOCKS/demo.md"; printf 'tail without newline'; } >> "$TARGET/docs/notes.md"
  sed -i '0,/Shipped line two./s//Edited by hand./' "$TARGET/docs/notes.md"
  printf 'New shipped text.\n\nWith a blank line.\n' > "$BLOCKS/demo.md"
  outside_before="$(outside "$TARGET/docs/notes.md"; echo x)"
  tail_before="$(tail -c 20 "$TARGET/docs/notes.md" | od -c)"
  run "$APPLY" --refresh
  assert_status 0
  assert_report
  assert_line "done managed-blocks: docs/notes.md: block demo refreshed from the Payload (edits inside its markers overwritten)"
  assert_line "done managed-blocks: docs/notes.md: block demo refreshed from the Payload"
  assert_eq "$outside_before" "$(outside "$TARGET/docs/notes.md"; echo x)" "text outside markers"
  assert_eq "$tail_before" "$(tail -c 20 "$TARGET/docs/notes.md" | od -c)" "file tail bytes"
  # Both blocks now carry the shipped content and its stamp.
  stamp="$(sha12 < "$BLOCKS/demo.md")"
  assert_eq 2 "$(grep -cFx "<!-- claude-config:begin demo $stamp -->" "$TARGET/docs/notes.md")" "fresh stamps"
  assert_eq 2 "$(grep -cFx 'With a blank line.' "$TARGET/docs/notes.md")" "fresh content"
  if grep -q 'Edited by hand' "$TARGET/docs/notes.md"; then fail "hand-edit inside markers survived"; fi
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_blocks_refresh_is_idempotent() {
  blocks_target
  write_doc CLAUDE.md
  printf 'Revised.\n' > "$BLOCKS/demo.md"
  run "$APPLY" --refresh
  assert_status 0
  before="$(snapshot "$TARGET")"
  touch "$TEST_TMP/ref"
  run "$APPLY" --refresh
  assert_status 0
  assert_report
  assert_line "skipped managed-blocks: CLAUDE.md: block demo current"
  assert_line_count 1
  assert_unchanged "$before" "$TARGET"
  assert_eq "" "$(find "$TARGET" -newer "$TEST_TMP/ref" -type f)" "files touched"
}

test_blocks_seeded_file() {
  blocks_target
  mkdir -p "$TARGET/docs/agents"
  seed="$TARGET/docs/agents/demo.md"
  { printf '<!-- claude-config:seed demo %s -->\n' "$(sha12 < "$BLOCKS/demo.md")"; cat "$BLOCKS/demo.md"; } > "$seed"
  git -C "$TARGET" add docs/agents/demo.md
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
  # Hand-edit below the header.
  echo 'Added by hand.' >> "$seed"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 2
  assert_line "drift managed-blocks: docs/agents/demo.md: seeded block demo edited inside its markers; $REFRESH_STEP to rewrite it (overwrites those edits)"
  run "$APPLY"
  assert_unchanged "$before" "$TARGET"
  # Payload moves on; refresh rewrites header and body.
  printf 'Seed v2.\n' > "$BLOCKS/demo.md"
  run "$APPLY" --refresh
  assert_status 0
  assert_line "done managed-blocks: docs/agents/demo.md: seeded block demo refreshed from the Payload (edits inside its markers overwritten)"
  expected="$(printf '<!-- claude-config:seed demo %s -->\nSeed v2.' "$(printf 'Seed v2.\n' | sha12)")"
  assert_eq "$expected" "$(cat "$seed")" "seeded file"
  run "$APPLY" --check
  assert_status 0
}

test_blocks_fork_by_deleting_markers() {
  blocks_target
  write_doc CLAUDE.md
  sed -i '/^<!-- claude-config:/d; s/Shipped line two./Forked by hand./' "$TARGET/CLAUDE.md"
  mkdir -p "$TARGET/docs"
  printf 'Forked seed, header removed.\n' > "$TARGET/docs/seed.md"
  git -C "$TARGET" add docs/seed.md
  printf 'Revised.\n' > "$BLOCKS/demo.md"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
  run "$APPLY" --refresh
  assert_status 0
  assert_line "skipped managed-blocks: no Managed Blocks in tracked markdown"
  assert_unchanged "$before" "$TARGET"
}

test_blocks_unknown_id_skipped() {
  blocks_target
  printf 'x\n' > "$TEST_TMP/x"
  { printf 'Intro.\n'; inline_block gone "$TEST_TMP/x"; } > "$TARGET/CLAUDE.md"
  git -C "$TARGET" add CLAUDE.md
  before="$(snapshot "$TARGET")"
  line='skipped managed-blocks: CLAUDE.md: block gone has no shipped source; left as it is (delete its markers to fork it)'
  run "$APPLY" --check
  assert_status 0
  assert_report
  assert_line "$line"
  run "$APPLY" --refresh
  assert_status 0
  assert_line "$line"
  assert_unchanged "$before" "$TARGET"
}

test_blocks_malformed_markers_left_alone() {
  blocks_target
  write_doc CLAUDE.md
  sed -i '/^<!-- claude-config:end /d' "$TARGET/CLAUDE.md"
  printf 'Revised.\n' > "$BLOCKS/demo.md"
  before="$(snapshot "$TARGET")"
  run "$APPLY" --refresh
  assert_status 0
  assert_report
  grep -q '^skipped managed-blocks: CLAUDE.md: line [0-9]*: block demo never ends; markers left as they are$' <<<"$output" \
    || fail "no malformed-marker line in: $output"
  assert_unchanged "$before" "$TARGET"
}

test_blocks_untracked_markdown_ignored() {
  blocks_target
  write_doc CLAUDE.md
  git -C "$TARGET" rm -q --cached CLAUDE.md
  sed -i 's/Shipped line two./Edited./' "$TARGET/CLAUDE.md"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

# End to end with the real shipped block, as Setup would place it.
test_blocks_real_shipped_block() {
  make_target
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  printf '# Mine\n<!-- claude-config:begin claude-config 000000000000 -->\n<!-- claude-config:end claude-config -->\n' \
    > "$TARGET/CLAUDE.md"
  git -C "$TARGET" add CLAUDE.md
  run "$APPLY" --check
  assert_status 2
  run "$APPLY" --refresh
  assert_status 0
  assert_line "done managed-blocks: CLAUDE.md: block claude-config refreshed from the Payload (edits inside its markers overwritten)"
  diff <(sed '1,2d;$d' "$TARGET/CLAUDE.md") "$TARGET/.claude/scripts/blocks/claude-config.md" \
    || fail "block content differs from the shipped source"
  run "$APPLY"
  run "$APPLY" --check
  assert_status 0
  assert_line_count 0
}

test_blocks_paths_with_spaces() {
  make_target "target with space"
  install_target
  echo '{}' > "$TARGET/.claude/claude-config.json"
  mkdir -p "$TARGET/sub dir"
  printf 'pre\n<!-- claude-config:begin claude-config 000000000000 -->\nold\n<!-- claude-config:end claude-config -->\npost' \
    > "$TARGET/sub dir/a b.md"
  git -C "$TARGET" add "sub dir/a b.md"
  run "$APPLY" --check
  assert_status 2
  assert_line "drift managed-blocks: sub dir/a b.md: block claude-config edited inside its markers; $REFRESH_STEP to rewrite it (overwrites those edits)"
  run "$APPLY" --refresh
  assert_status 0
  assert_eq pre "$(head -n1 "$TARGET/sub dir/a b.md")" "first line"
  assert_eq "$(printf -- '-->\npost' | od -c)" "$(tail -c 8 "$TARGET/sub dir/a b.md" | od -c)" "tail bytes"
  run "$APPLY"
  run "$APPLY" --check
  assert_status 0
}

test_blocks_refresh_without_intent_is_noop() {
  make_target
  install_target
  printf '<!-- claude-config:begin claude-config 000000000000 -->\n<!-- claude-config:end claude-config -->\n' \
    > "$TARGET/CLAUDE.md"
  git -C "$TARGET" add CLAUDE.md
  before="$(snapshot "$TARGET")"
  run "$APPLY" --refresh
  assert_status 0
  assert_line 'skipped intent: no .claude/claude-config.json; run /setup-claude-config to create it'
  assert_unchanged "$before" "$TARGET"
}
