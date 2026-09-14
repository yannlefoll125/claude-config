# Claude Code multi-account switching — draft

> Hand-off document. Written 2026-09-11 from a research session on
> swapping Claude Code accounts without redoing the OAuth login each
> time. Self-contained; nothing has been implemented yet.

## Problem

One machine, several Claude accounts (e.g. personal and work
subscriptions). Claude Code has no built-in account switcher and no
plugin for it; naively, switching means `/login` — a browser OAuth
dance — every time. Wanted: log in once per account, then switch with
a single command.

## Verified facts (2026-09-11)

- Credentials on Linux live at `$CLAUDE_CONFIG_DIR/.credentials.json`
  (default `~/.claude/`), mode 0600. The path is always derived from
  the config dir; **no env var or setting targets the credentials file
  alone** ([auth docs](https://code.claude.com/docs/en/authentication)).
- The file is **mutable during sessions**: Claude Code writes refreshed
  tokens back with no file locking
  ([#56339](https://github.com/anthropics/claude-code/issues/56339)).
  Concurrent processes already race on the single-use refresh token
  ([#24317](https://github.com/anthropics/claude-code/issues/24317)).
- **Symlinking the file doesn't survive**: writes replace the symlink
  with a regular file, so a swap-the-symlink scheme diverges after the
  first refresh.
- `~/.claude.json` also carries OAuth account metadata (userID,
  subscription state); swapping only `.credentials.json` may leave
  stale identity state. Unconfirmed how much this matters.
- Tokens are **opaque** (`sk-ant-oat01-…` access, `sk-ant-ort01-…`
  refresh), not JWTs; access-token expiry sits beside the token as
  `expiresAt`. Refresh-token TTL is server-side only and
  **undocumented**. Empirical: survives a full weekend idle (owner's
  observation); guess ~1 week. Bug reports claiming ~24 h
  ([#72532](https://github.com/anthropics/claude-code/issues/72532))
  describe a broken refresh path, not the designed TTL. The documented
  "login expires in 3 days" warning implies a lifetime well beyond 24 h.
- `apiKeyHelper` is for API keys, not subscription OAuth tokens — not
  an escape hatch.
- `claude setup-token` mints a 1-year token for
  `CLAUDE_CODE_OAUTH_TOKEN` (documented); model requests only — no
  Remote Control, no claude.ai connectors. Right tool for headless
  scripts, not for interactive daily driving.

## The model

Per-account **profile directories** via `CLAUDE_CONFIG_DIR` — the only
mechanism that isolates the mutable credentials file, which is what
makes it safe:

```bash
alias claude-personal='CLAUDE_CONFIG_DIR=~/.claude-personal claude'
alias claude-work='CLAUDE_CONFIG_DIR=~/.claude-work claude'
```

One `/login` per profile, ever (as long as each profile is used often
enough to keep its tokens rotating). Both accounts can run
side-by-side in different terminals.

**Shared-config refinement** (untested): a full config dir per account
duplicates settings/plugins/history. Mitigation: keep the real
`~/.claude` for account A; for account B create a dir where everything
*except* `.credentials.json` (and per-session state) is symlinked back
to `~/.claude`. Claude Code only rewrites credentials and session
state, so read-mostly config shared via symlinks should hold — needs a
prototype to confirm which files must stay real vs. can be links.

Rejected alternative: swapping `.credentials.json` in place between
accounts. Works only if *no* Claude Code process is running (refresh
write-backs clobber otherwise), leaves `~/.claude.json` metadata
stale, and buys nothing over profile dirs.

## Open questions

1. Which files in the config dir must be per-profile vs. shareable via
   symlink? (Prototype: strace/inotify a session, watch what gets
   written.)
2. Actual refresh-token TTL — measure by letting a dormant profile age;
   check `expiresAt` deltas after each login.
3. Does `~/.claude.json` (outside the config dir?) interact with
   `CLAUDE_CONFIG_DIR`, or does each profile get its own copy?
4. Does this repo want to ship the aliases/profile-setup as a script
   (`claude-profile <name>`) the way it ships skills?

## Sources

- https://code.claude.com/docs/en/authentication
- https://github.com/anthropics/claude-code/issues/56339 (refresh races)
- https://github.com/anthropics/claude-code/issues/24317 (concurrent refresh)
- https://github.com/anthropics/claude-code/issues/72532 (daily re-auth reports)
- claude-swap (macOS Keychain swapper, prior art):
  https://gist.github.com/fortunto2/b326e4727e32f9af1742f0710dcc5f75
