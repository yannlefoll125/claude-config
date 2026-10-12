---
name: install-mattpocock
description: Configure the mattpocock-skills plugin from the Intent (.claude/claude-config.json, key mattpocock) — run its setup skill straight from the plugin cache on disk (no reload needed) and place the resulting prose as Managed Blocks. Apply installs the plugin; Setup chains into this skill. Safe to re-run.
argument-hint: "overrides to the Intent's mattpocock answers — or 'interactive' to answer every setup question yourself"
disable-model-invocation: true
---

Configure Matt Pocock's skills plugin in the current project from its Intent, end to end, without stopping. The user knows this workflow — don't re-explain it, just run it and report each step's outcome in one line.

## Ground rules

- **The answers live in the Intent**, `.claude/claude-config.json`, under the `mattpocock` key; its sub-keys, types and values are listed in the "Intent keys" section of `.claude/scripts/apply`'s header — read it first. The skill carries no answers of its own: a decision not in the Intent is asked (interactive) or taken from the plugin setup's own stated default, and either way recorded in the Intent before anything is written.
- **Never install the plugin.** Apply does that from the Intent's `plugins` key; this skill never runs `claude plugin install`.
- **Everything written into markdown is a Managed Block** (grammar in the `.claude/scripts/apply` header): inline begin/end markers in the instructions file, a seed header on each whole `docs/agents/*.md` file. Never edit a byte outside the markers of the blocks this skill owns.
- Run everything from the project root, `git rev-parse --show-toplevel` (or the session's working directory when the project is not a git repo). If `.claude/scripts/apply` is missing, stop: say so in one line and point at `claude-config-install` for this project.

## Arguments

- No arguments → the Intent's answers, fully automatic: no questions, no waiting on the user.
- **`interactive`** anywhere in the arguments → run the setup skill's interactive process as written (present findings, ask its questions, let the user edit drafts); every answer is recorded in the Intent (step 1) before any file is written.
- Anything else → overrides, each landing in the `mattpocock` sub-key it matches, every other sub-key kept: "GitHub issues" → `issueTracker: "github"`; "Jira, …" → `issueTracker: "other"` plus `issueTrackerWorkflow` with the described workflow; "label needs-triage as bug:triage" → that `triageLabels` entry; "multi-context" → `domainDocs`; "AGENTS.md" → `instructionsFile`; "no sub-efforts" / "no handback" → drop that entry from `overlays`.

## Step 1 — read and record the answers

Read `.claude/claude-config.json`. No file, or no `mattpocock` object and not `interactive` → stop: say so in one line and point at `/setup-claude-config` (which writes it) or `/install-mattpocock interactive`.

Apply the arguments on top of the `mattpocock` object. In interactive mode, step 3's answers land here too. A sub-key the object lacks takes the setup skill's own stated default for that section (`instructionsFile`: the first that exists of `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`, else `CLAUDE.md`). When anything changed, rewrite the whole Intent — every other top-level key verbatim, two-space indent, final newline — and verify it parses: `jq -e '.mattpocock | type == "object"' .claude/claude-config.json`. Report "Intent updated (<sub-keys>)" or "Intent unchanged". Act only on the written Intent.

## Step 2 — verify the plugin and locate it on disk

The plugin is the `plugins` entry `mattpocock-skills@<marketplace>`. It is present when both hold:

- `jq -e --arg p "mattpocock-skills@<marketplace>" '.enabledPlugins[$p] == true' .claude/settings.json`
- a cache dir `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/cache/<marketplace>/mattpocock-skills/<version>/` exists — if there are several, take the highest by `sort -V` (1.10.0 > 1.9.0).

Missing → stop. If `plugins` doesn't list it, say to add `"mattpocock-skills@claude-plugins-official"` to the Intent's `plugins` and run `/apply-claude-config`; if it does, say to run `/apply-claude-config` (Apply installs per environment, and skips when the `claude` CLI isn't on PATH). Then re-run this skill.

Newly installed plugin skills aren't registered with the running session, and the reload commands (`/reload-plugins`, `/reload-skills`) are user-typed only — do NOT wait for them. The setup skill lives at `skills/engineering/setup-matt-pocock-skills/` inside the cache dir, alongside its seed templates (`issue-tracker-local.md`, `triage-labels.md`, `domain.md`, …).

## Step 3 — run the setup skill from disk, into scratch files

Read `SKILL.md` from that folder and follow its explore and answer steps as if invoked, taking every answer from the Intent's `mattpocock` object; in interactive mode, ask its questions instead, leading with the Intent's value as the recommendation, and record the answers (step 1) before going on. Its own rules still decide what exists at all — e.g. no triage-labels file when the `triage` skill isn't in the plugin.

Don't let it write into the project: produce each artifact's content in a scratch dir (`tmp="$(mktemp -d)"`), one file per block id:

| Block id | Content | Lands in |
|---|---|---|
| `agent-skills` | the setup skill's `## Agent skills` block, summaries from the Intent | inline, in `instructionsFile` |
| `issue-tracker` | the tracker template for `issueTracker` (or, for `"other"`, `issueTrackerWorkflow` as prose); with `issue-tracker-sub-efforts` in `overlays` and a local tracker, edited per [issue-tracker-sub-efforts.md](./issue-tracker-sub-efforts.md) | seeded, `docs/agents/issue-tracker.md` |
| `triage-labels` | the template, right-hand column from `triageLabels` | seeded, `docs/agents/triage-labels.md` |
| `domain` | the template, for `domainDocs` | seeded, `docs/agents/domain.md` |

`main-flow-handback` (with that entry in `overlays`) is not generated: its content ships as `.claude/scripts/blocks/main-flow-handback.md`, so Apply checks it and `/apply-claude-config refresh` keeps it current. It closes a gap the plugin leaves: its `/grilling` exit reads any confirmation as a green light, so nothing stops a session improvising a spec and tickets freehand.

In non-interactive mode, skip the setup skill's confirm-drafts step. In interactive mode, show the drafts; an edit that changes a decision goes into the Intent and the draft is regenerated. Wording the user wants to keep belongs outside the markers — anything inside is regenerated on every run — or in a forked copy.

## Step 4 — place the blocks

Stamp every block the same way: `hash="$(awk 1 "$tmp/<id>.md" | sha256sum | cut -c1-12)"` — the first 12 hex of sha256 over the content with a final newline guaranteed. For `main-flow-handback` the content file is `.claude/scripts/blocks/main-flow-handback.md`. Copy content with the shell, never by retyping.

**Inline blocks** (`agent-skills`, then `main-flow-handback`) in `instructionsFile`, creating it when absent; never touch `~/.claude/CLAUDE.md`:

1. **Placed** — a line starting `<!-- claude-config:begin <id> ` exists:
   - `main-flow-handback` → leave it; Apply's report covers it. Report "already placed".
   - `agent-skills` → if the begin marker's stamp equals `$hash`, report "current" and don't write the file. Otherwise, before rewriting, compare the stamp with the hash of the lines strictly between the markers (`sed -n '<begin+1>,<end-1>p' <file> | sha256sum | cut -c1-12`): a mismatch means hand-edits inside the markers — in interactive mode ask before overwriting them; otherwise overwrite and say so. Rewrite in place, replacing only the begin marker and the content lines:

     ```
     awk -v id=agent-skills -v hash="$hash" -v src="$tmp/agent-skills.md" '
       $0 ~ "^<!-- claude-config:begin " id " " { print "<!-- claude-config:begin " id " " hash " -->"; while ((getline l < src) > 0) print l; skip = 1; next }
       skip && $0 == "<!-- claude-config:end " id " -->" { skip = 0 }
       !skip' "$f" > "$tmp/out" && cat "$tmp/out" > "$f"
     ```
2. **Forked** — no markers, but the block's heading line is present (`## Agent skills`, `### Main-flow handback`) → the user removed the markers to own it, or it predates them: leave it. Report "forked; left as it is". In interactive mode, offer to adopt it: replace that section with the placed block.
3. **Place** — otherwise insert as its own section: `agent-skills` at the end of the file, `main-flow-handback` directly after the `agent-skills` end marker (or after the end of a forked `## Agent skills` section). One blank line on each side, outside the markers:

   ```
   { printf '<!-- claude-config:begin %s %s -->\n' "$id" "$hash"; awk 1 "$src"; printf '<!-- claude-config:end %s -->\n' "$id"; }
   ```

**Seeded files** (`issue-tracker`, `triage-labels`, `domain`), each `docs/agents/<id>.md`:

1. **Placed** — line 1 is `<!-- claude-config:seed <id> <stamp> -->` → stamp equals `$hash`: "current", not written. Otherwise check for hand-edits as above (`tail -n +2 <file> | sha256sum | cut -c1-12` against the stamp), then rewrite the whole file.
2. **Forked** — the file exists without a seed header → leave it, as for inline blocks (interactive: offer to adopt).
3. **Place** — otherwise: `mkdir -p docs/agents; { printf '<!-- claude-config:seed %s %s -->\n' "$id" "$hash"; awk 1 "$tmp/$id.md"; } > "docs/agents/$id.md"`.

A dropped overlay or a block the setup skill no longer produces (e.g. `triage-labels`) is removed with its markers if placed — the whole file for a seed — and left alone if forked.

## Step 5 — verify

Each placed or rewritten block's content hashes to its stamp (the same `sed`/`tail` commands as step 4). Then `.claude/scripts/apply --check`: it must exit 0 with no `managed-blocks` drift line. Its expected output for these blocks is one `skipped managed-blocks: … has no shipped source` line each for `agent-skills` and the seeded files — content generated per project has no Payload source, so Apply leaves it to this skill — and nothing for a current `main-flow-handback`. New or untracked files are invisible to Apply until committed; committing is the user's step.

## Wrap up

Finish with a short checklist: Intent (updated / unchanged), plugin (marketplace + version), each block id (placed / rewritten / current / forked / removed, and its file). Then remind the user — no waiting — that the plugin's slash commands appear after they type `/reload-plugins` and `/reload-skills`, or in any new session, and that later changes go through the Intent: edit its `mattpocock` key and re-run `/install-mattpocock`.
