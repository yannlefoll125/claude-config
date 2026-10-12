# Sourced by tests/run into each test's subshell. Tests drive only the real
# executables' CLIs; nothing here reaches into script internals.

setup_test() {
  TEST_TMP="$(mktemp -d)"
  # Install subscribes its Target; keep that out of the real ~/.config.
  export XDG_CONFIG_HOME="$TEST_TMP/xdg"
  FAKE_BIN="$TEST_TMP/fake-bin"
  STUB_LOG="$TEST_TMP/stub-calls"
  mkdir -p "$FAKE_BIN"
  : > "$STUB_LOG"
  export PATH="$FAKE_BIN:$PATH" STUB_LOG
}

teardown_test() {
  rm -rf "$TEST_TMP"
}

fail() {
  echo "assertion failed: $*" >&2
  exit 1
}

# make_target [name] — fresh git repo acting as a Target; sets TARGET and APPLY.
make_target() {
  TARGET="$TEST_TMP/${1:-target}"
  mkdir -p "$TARGET"
  git -C "$TARGET" init -q
  APPLY="$TARGET/.claude/scripts/apply"
}

# install_target — run the real installer into $TARGET.
install_target() {
  "$REPO/claude-config-install" "$TARGET" >/dev/null
}

# stub <name> [body] — fake external on PATH. Default body logs "<name> <args>"
# to $STUB_LOG and exits 0; a custom body is shell code run with the call's args.
stub() {
  local name="$1" body="${2:-}"
  {
    echo '#!/usr/bin/env bash'
    printf 'printf "%%s\\n" "%s $*" >> "$STUB_LOG"\n' "$name"
    printf '%s\n' "$body"
  } > "$FAKE_BIN/$name"
  chmod +x "$FAKE_BIN/$name"
}

# stub_calls <name> — the logged invocations of a stub, one per line.
stub_calls() {
  grep "^$1\( \|$\)" "$STUB_LOG" || true
}

# run <cmd...> — capture exit code, stdout and stderr into $status, $output, $stderr.
run() {
  local out="$TEST_TMP/.run-out" err="$TEST_TMP/.run-err"
  status=0
  "$@" >"$out" 2>"$err" || status=$?
  output="$(cat "$out")"
  stderr="$(cat "$err")"
}

assert_status() {
  [ "$status" -eq "$1" ] || fail "expected exit $1, got $status (stdout: $output; stderr: $stderr)"
}

assert_eq() { # assert_eq <expected> <actual> [what]
  [ "$1" = "$2" ] || fail "${3:-value}: expected '$1', got '$2'"
}

# assert_line <exact-line> — stdout contains the line verbatim.
assert_line() {
  grep -Fxq -- "$1" <<<"$output" || fail "no stdout line '$1' in:"$'\n'"$output"
}

assert_line_count() {
  local n=0
  [ -z "$output" ] || n="$(wc -l <<<"$output")"
  [ "$n" -eq "$1" ] || fail "expected $1 stdout lines, got $n:"$'\n'"$output"
}

# assert_report — every stdout line follows Apply's report convention.
assert_report() {
  local line
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [[ "$line" =~ ^(done|skipped|drift)\ [a-z0-9-]+:\ .+$ ]] || fail "not a report line: '$line'"
  done <<<"$output"
}

# snapshot <dir> — paths, types, modes, link targets and content hashes of a tree.
snapshot() {
  (cd "$1" && find . -printf '%p %y %m %l\n' | LC_ALL=C sort \
    && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum)
}

# assert_unchanged <snapshot-before> <dir> — the tree matches the earlier snapshot.
assert_unchanged() {
  local diff
  diff="$(diff <(printf '%s\n' "$1") <(snapshot "$2"))" || fail "tree $2 changed:"$'\n'"$diff"
}
