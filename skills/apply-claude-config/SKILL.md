---
name: apply-claude-config
description: Converge the current project to its Intent (.claude/claude-config.json) by running its deployed Apply script, and relay the report. Use when the session-start check reports drift, or after hand-editing the Intent. 'check' runs the read-only check instead; 'refresh' rewrites drifted Managed Blocks.
argument-hint: "'check' for a read-only drift check, 'refresh' to rewrite drifted Managed Blocks — omit to converge"
disable-model-invocation: true
---

Run the project's own Apply and relay what it says. Apply does all the work; this skill only runs it in this session's environment, so environment-dependent policies are evaluated where they are consumed.

From the project root, in this session's own shell (never on another machine or through another environment):

- No arguments → `.claude/scripts/apply`
- `check` → `.claude/scripts/apply --check`
- `refresh` → `.claude/scripts/apply --refresh` — rewrites drifted Managed Blocks in tracked markdown from the Payload, overwriting hand-edits inside their markers; text outside the markers is never touched. Leave the resulting diff for the user to review and commit.

Then:

- Relay stdout verbatim — one line per action, in the order printed. Don't summarise, merge, reorder or reword the lines.
- On a nonzero exit, relay stderr verbatim as well. In check mode, exit 2 means drift and 3 means no Intent — both already explained by the printed lines, not failures; exit 1 is a failure in any mode.
- Don't act on the report — no edits, no installs, no follow-up runs. If a line names a next step (`/setup-claude-config`, `claude-config-install`, `/apply-claude-config refresh`), pass it on as the user's step.
- If `.claude/scripts/apply` is missing or not executable, say so in one line and point at `claude-config-install` for this project.
