---
name: install-mattpocock
description: Fire-and-forget install of the mattpocock-skills plugin at project level, then run its setup skill straight from the plugin cache on disk (no reload needed) with our standard answers (local markdown issue tracker, default triage labels, local CLAUDE.md).
argument-hint: "overrides to the standard setup — or 'interactive' to answer every setup question yourself"
disable-model-invocation: true
---

Install and configure Matt Pocock's skills plugin in the current project, end to end, without stopping. The user knows this workflow — don't re-explain it, just run it and report each step's outcome in one line.

## Arguments

- No arguments → the standard install below, fully automatic: no questions, no waiting on the user.
- **`interactive`** anywhere in the arguments → same steps, but do NOT auto-answer: run the setup skill's interactive process as written (present findings, ask its questions, let the user edit drafts before writing).
- Anything else → instructions that override details of the install or the setup answers (e.g. a different marketplace, GitHub issues instead of markdown, custom triage labels, AGENTS.md instead of CLAUDE.md). Apply them to the matching step and keep the defaults for everything not mentioned.

## Step 1 — install the plugin (project level)

```
claude plugin install --scope project mattpocock-skills@claude-plugins-official
```

Project scope is required: the plugin entry must land in the project's `.claude/settings.json`, not the user's global settings. If the plugin is already installed, say so and move on — this skill is safe to re-run.

## Step 2 — locate the plugin on disk (no reload needed)

Newly installed plugin skills aren't registered with the running session, and the reload commands (`/reload-plugins`, `/reload-skills`) are user-typed only — do NOT wait for them. The plugin's files are already on disk; use them directly.

Find the cache directory: `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/<version>/` — take the highest version directory if there are several. The setup skill lives at `skills/engineering/setup-matt-pocock-skills/` inside it, alongside its seed templates (`issue-tracker-local.md`, `triage-labels.md`, `domain.md`, …).

## Step 3 — run the setup skill from disk

Read `SKILL.md` from that setup-skill folder and follow it as if invoked, with these standard answers (unless the arguments or interactive mode say otherwise):

- **Issue tracker**: local markdown — the `.scratch/<feature-slug>/` layout, seeded from the skill's `issue-tracker-local.md` template.
- **Triage labels**: keep the defaults, verbatim: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
- **Agent-skills block**: local CLAUDE.md — edit the project's existing CLAUDE.md (root or `.claude/`); create a root `CLAUDE.md` if the project has neither it nor `AGENTS.md`. Never touch the global `~/.claude/CLAUDE.md`.

In non-interactive mode, also skip the setup skill's confirm-drafts step: write the files directly. Respect its idempotency rules — update an existing `## Agent skills` block in place, never duplicate it, and leave existing `docs/agents/*.md` alone unless an argument asks to change them. If setup asks something these answers don't cover, use its own stated default; only ask the user when there is none.

## Wrap up

Finish with a short checklist: plugin installed (scope + version), setup files written or already present (`docs/agents/*.md`, the `## Agent skills` block). Then remind the user — no waiting — that the plugin's slash commands appear after they type `/reload-plugins` and `/reload-skills`, or in any new session.
