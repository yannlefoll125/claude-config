---
name: setup-claude-config
description: Companion to claude-config-install — decide this project's configuration and record it as the Intent (.claude/claude-config.json), then run Apply to converge it, place the claude-config Managed Block, and chain into install-mattpocock. Standard answers - auto permission mode when virtualised, notifications off, Fable model, statusline, staleness hook. Safe to re-run; arguments amend the Intent.
argument-hint: "Intent overrides — e.g. 'keep notifications', 'skip mattpocock', 'model sonnet', 'auto mode anyway', 'arm commit-msg', 'track intent'"
disable-model-invocation: true
---

Decide this project's configuration, record it as the Intent, and let Apply do the rest. `claude-config-install` copied the Payload (this skill arrived through it); this skill only decides. Everything mechanical — settings keys, virtualisation detection, statusline wiring, the staleness hook, git hook symlinks, plugin installs, Managed Block refresh — is the Target's own `.claude/scripts/apply`. Report each step's outcome in one line.

## Ground rules

- **Setup writes three things only**: `.claude/claude-config.json`, the clone-local git exclude line (step 4), and the initial placement of the `claude-config` Managed Block (step 6). Never write `.claude/settings.local.json` or `.claude/settings.json`, never create hook symlinks, never run `claude plugin install` — record the decision in the Intent and run Apply.
- **Policies, never outcomes.** Record what was decided, never what this environment yields: `permissionMode` stays `"auto-if-virtualised"` whether or not this machine is virtualised; `model` is the model as decided, never probed (an unavailable model falls back silently). Never run a virtualisation check or a model test.
- **The key list lives in the header of `.claude/scripts/apply`** (the "Intent keys" section: names, types, defaults). Read it before deciding; the table in step 2 names the decisions, the header is authoritative. A key the header doesn't list is not Apply's — don't invent one.
- Run everything from the project root, `git rev-parse --show-toplevel` (or the session's working directory when the project is not a git repo).
- If `.claude/scripts/apply` is missing or not executable, stop: say so in one line and point at `claude-config-install` for this project.

## Arguments

- No arguments → the standard answers (step 2) on a first run; the existing Intent on a re-run.
- Anything else → overrides, each landing in the Intent key it matches, every other key kept: "keep notifications" → `notifications: true`; "model sonnet" → `model: "sonnet"`; "no model" → drop `model`; "auto mode anyway" → `permissionMode: "auto"`; "no auto mode" → `permissionMode: "default"`; "no statusline" → `statusline: false`; "no staleness hook" → `stalenessHook: false`; "arm commit-msg" → add `"commit-msg"` to `gitHooks`; "skip mattpocock" → drop `mattpocock-skills@claude-plugins-official` from `plugins` (and step 7 skips). Two overrides are not Intent keys: "track intent" (step 4) and "skip blocks" (step 6). Overrides meant for the mattpocock setup pass through to step 7.

## Step 1 — explore the Target

Read, without writing anything:

- the "Intent keys" section of `.claude/scripts/apply`'s header;
- `.claude/claude-config.json`, if present — on a re-run it is the starting answers;
- the shipped hooks, `ls .claude/scripts/git-hooks/`, and each hook's header comment (what it does);
- whether the Intent is tracked: `git ls-files --error-unmatch -- .claude/claude-config.json 2>/dev/null` (exit 0 tracked, nonzero not);
- the instructions file the block goes into (step 6): `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`.

Settings already in `.claude/settings.local.json` are residue, not answers: never derive an Intent value from them.

## Step 2 — decide

| Decision | Intent key | Standard answer |
|---|---|---|
| Session-start drift check | `stalenessHook` | `true` |
| Model | `model` | `"claude-fable-5"` |
| Notifications | `notifications` | `false` |
| Permission mode policy | `permissionMode` | `"auto-if-virtualised"` |
| Statusline | `statusline` | `true` — written explicitly: Apply's default is `false` |
| Git hooks to arm | `gitHooks` | `[]` — offer each shipped hook by its header comment |
| Project-scope plugins | `plugins` | `["mattpocock-skills@claude-plugins-official"]` |

Start from the existing Intent when there is one, else from the standard answers; apply the arguments on top. Then:

- **First run** (no Intent): show the proposed Intent, one line per key with its value, and ask once for confirmation or changes. Write after the answer.
- **Re-run with arguments**: write the amended Intent without asking.
- **Re-run without arguments**: show the current Intent and ask what to change; "nothing" keeps it as it is and continues with step 4.

Keys in an existing Intent that the table doesn't name (hand-added, or another skill's) are kept verbatim. Plugins already listed stay listed unless an argument drops them.

## Step 3 — write the Intent

Write `.claude/claude-config.json` as one JSON object: every key from the table written explicitly, even when it equals Apply's default (the file documents the project), followed by any kept keys; two-space indent, final newline. Rewrite the whole file — never append. Verify it parses: `jq -e 'type == "object"' .claude/claude-config.json`.

## Step 4 — tracked or excluded

Never assume either state; decide from git each run. Skip this step with one line when the project is not a git repo.

```
git ls-files --error-unmatch -- .claude/claude-config.json 2>/dev/null
exclude="$(git rev-parse --git-path info/exclude)"
```

- **Tracked** (exit 0) → never exclude. If `grep -Fx '/.claude/claude-config.json' "$exclude"` finds the line, delete it; otherwise leave the file alone. Report "tracked; not excluded".
- **Not tracked, argument "track intent"** → don't exclude; delete the line if present. Report "untracked; committing it is the user's step" (`git add .claude/claude-config.json`) — on a later run while it is still uncommitted, "track intent" is needed again.
- **Not tracked** → unless `grep -Fxq '/.claude/claude-config.json' "$exclude"` already matches, append that exact line (`mkdir -p "$(dirname "$exclude")"`; add a newline first if the file doesn't end with one). Report "excluded via .git/info/exclude" or "already excluded".

## Step 5 — run Apply

From the project root, in this session's own shell: `.claude/scripts/apply`.

- Relay stdout verbatim — one line per action, in the order printed; don't summarise, merge, reorder or reword.
- Nonzero exit is Setup's failure: relay stderr verbatim and stop — no placement, no chaining. Fix the Intent if the error names it, then re-run this step; anything else goes to the user.
- Don't act on report lines by hand. A `skipped plugins` line for a plugin enabled but not in the Intent is the user's decision: pass it on.

## Step 6 — place the `claude-config` Managed Block

The one placement only an agent can do; once placed, Apply checks it and `/apply-claude-config refresh` keeps it current. Setup places only block id `claude-config`; other ids in `.claude/scripts/blocks/` belong to the skill that ships them. Skip with one line on "skip blocks".

1. **Pick the file**: the first that exists of `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`; none → create root `CLAUDE.md`. Never touch `~/.claude/CLAUDE.md`.
2. **Already placed** — the file contains a line starting `<!-- claude-config:begin claude-config ` → leave it untouched; Apply's report already covers it. Report "already placed".
3. **Forked** — no markers, but a line `## Claude Code configuration` is present → the user removed the markers to own it; leave it. Report "forked; left as it is".
4. **Place** — otherwise insert the block as its own section: at the end of the file, or, where the file already has a section about its Claude Code setup, directly after that section. Never edit a byte outside the inserted lines. Copy the content with the shell, not by retyping:

   ```
   src=.claude/scripts/blocks/claude-config.md
   hash="$(awk 1 "$src" | sha256sum | cut -c1-12)"
   { printf '<!-- claude-config:begin claude-config %s -->\n' "$hash"; awk 1 "$src"; printf '<!-- claude-config:end claude-config -->\n'; }
   ```

   Separate the block from surrounding text by one blank line on each side (the blank lines sit outside the markers). For end-of-file placement, append that output to the file after the separator line; for a mid-file spot, insert the same lines there.
5. **Verify**: the lines strictly between the markers hash to the stamp — `sed -n '<begin+1>,<end-1>p' <file> | sha256sum | cut -c1-12` equals `$hash`. If the file is tracked, `.claude/scripts/apply --check` prints no `managed-blocks` line for it. A new or untracked file is invisible to Apply until committed — committing is the user's step.

## Step 7 — chain into install-mattpocock

When the Intent's `plugins` lists `mattpocock-skills@claude-plugins-official`, invoke the `install-mattpocock` skill (deployed alongside this one), passing through any arguments that concern it. If the Skill tool does not list it yet (fresh copy, session not reloaded), read `.claude/skills/install-mattpocock/SKILL.md` and follow it directly. It is safe to re-run. Not listed → skip with one line.

## Wrap up

Finish with a one-line-per-step checklist: Intent (written / unchanged), git status (tracked / excluded / already excluded / untracked by request / not a git repo), Apply (exit code; its lines were relayed above), block (placed in `<file>` / already placed / forked / skipped), mattpocock (run / skipped). Then remind the user:

- settings changes are picked up by a new session — `/reload-skills` does not apply them; from then on the staleness hook runs `apply --check` at session start and stays silent while the Target matches its Intent;
- a project-level `permissions.defaultMode: "auto"` is this suite's convention, though the docs claim it is honoured only in `~/.claude/settings.json` — a session not picking it up means moving the key there by hand;
- later changes go through the Intent: edit `.claude/claude-config.json` and run `/apply-claude-config`, or re-run `/setup-claude-config` with overrides.
