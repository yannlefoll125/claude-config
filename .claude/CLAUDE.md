# CLAUDE.md

## Skill authoring in this repo

- Skills are authored under `skills/` at the repo root, but Claude Code only loads them from `.claude/skills/`. Install by copying (`./claude-config-install <project>` at the repo root does this for any project, including this one); commit both copies.
- When to install/push: run `claude-config-install`/`claude-config-push` for this repo only as part of committing (sync the `.claude/` copies in the same commit as their sources), or when the user explicitly asks. Never auto-install after edits — work in progress must not be dogfooded into the live `.claude/` config until it's commit-worthy.
- Consuming flow: `make install` once symlinks `claude-config-install` and `claude-config-push` into `~/.local/bin` (the scripts resolve the symlink back to this repo, so a plain copy would break it). Then in any project: `claude-config-install` (defaults to `.`) followed by `/setup-claude-config` in a session there. Base settings land in that project's `.claude/settings.local.json`, gitignored here.
- Subscriptions: `claude-config-install` records the target in `~/.config/claude-config/subscribers` (one absolute path per line, `#` comments allowed); `claude-config-push` re-installs into every listed path, warning and skipping paths that don't exist (they stay subscribed). Install writes `.claude/.claude-config-manifest` in the target and on the next run deletes only files listed there that the repo no longer ships — project-specific files in the managed dirs are never touched.
- Settings facts verified 2026-08-29: `preferredNotifChannel: "notifications_disabled"` is the real notifications-off value (the docs' settings reference doesn't list it); an unavailable `model` value falls back silently; the docs claim `permissions.defaultMode: "auto"` only works in `~/.claude/settings.json`, but this repo uses it project-level as its convention.
- After editing an installed skill, `/reload-skills` may report "no changes" and the next invocation may still serve the stale cached body once — verify against the file on disk.
- `claude plugin install/uninstall --scope project` reads and writes `enabledPlugins` in the project's `.claude/settings.json`; uninstall fails without the matching `--scope`. Plugin files land in `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` immediately on install and are usable from there without any reload.
- In this Sandbox, `/workspaces` is root-owned; only the home directory is writable for scratch projects.

## Agent skills

### Issue tracker

Issues live as local markdown files under `.scratch/<feature-slug>/` in this repo. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, used verbatim (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — one `CONTEXT.md` plus `docs/adr/` at the repo root. See `docs/agents/domain.md`.
