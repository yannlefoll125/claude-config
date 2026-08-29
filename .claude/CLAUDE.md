# CLAUDE.md

## Skill authoring in this repo

- Skills are authored under `skills/` at the repo root, but Claude Code only loads them from `.claude/skills/`. Install by copying (`./claude-config-install <project>` at the repo root does this for any project, including this one); commit both copies.
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
