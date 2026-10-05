---
name: doc-review-gather
description: Sweep project documentation for defects — stale or incorrect claims, contradictions, duplication, orphans, gaps, ambiguity, misplacement, noise — and file one ticket per finding. Use when asked to review, audit, or health-check docs, or to check the docs a session touched before a handoff.
argument-hint: "scope — file paths, or \"session\" for docs tied to this session's work; empty = full sweep"
---

Sweep the project's prose documentation, verify its claims, and file a ticket per finding. This skill's product is the ticket backlog; working it is `doc-review-fix`'s job.

## Scope

- No arguments → the full doc set.
- Paths → just those files.
- `session` → docs tied to this session's work: the prose docs the session touched, plus the docs describing what it touched. A dispatching caller (a handoff, a subagent launch) has to supply the touched-file list in its prompt — a fresh subagent has no session of its own to inspect.

## The doc set

Discover the landscape instead of assuming a layout: start from `git ls-files '*.md' '*.mdx' '*.rst' '*.adoc' '*.txt'` (widen the pathspec if this project writes docs in another format) and keep the prose docs — README, AGENTS.md / CLAUDE.md, CONTEXT.md, `docs/**`, and peers. Drop skill and command files (`SKILL.md`, anything under `.claude/` or a plugin cache — they have their own authoring discipline) and scratch, generated, vendored, or mechanically mirrored copies.

## Defect taxonomy

Classify every finding under one category:

- **stale** — was true, the code moved.
- **incorrect** — born false.
  These two present as a single defect: the doc disagrees with code or reality. Record that as **wrong**, refining to stale or incorrect only when a cheap `git log`/`git blame` settles the origin.
- **orphaned** — its subject no longer exists.
- **contradictory** — two docs disagree; the fix is deciding the truth.
- **duplicated** — one meaning in two places; the fix is picking the canonical home. Distinct from contradictory: the copies still agree — for now.
- **incomplete** — a gap a reader needs filled.
- **ambiguous** — supports multiple readings.
- **misplaced** — true, but in the wrong document.
- **noise** — true and useless; earns no load.

## The sweep

Read every in-scope doc in full. For each claim with a source of truth in the repo — a path, a command, a config value, a described behaviour — check it against that source. On a large doc set, fan the per-doc reads out to subagents and keep the claim-verification judgments yourself.

Done when every in-scope doc is accounted for and every checkable claim was checked.

## Tickets

Findings are tickets under `.claude/doc-review/`. The structure below is this skill's own, defined here in full — whatever issue tracker the project uses plays no part. Keep the directory out of version control: if `git check-ignore -q .claude/doc-review/` fails, append `.claude/doc-review/` to `$(git rev-parse --git-common-dir)/info/exclude` (not a literal `.git/` path — that breaks in worktrees).

```
.claude/doc-review/
├── issues/NN-<slug>.md    ← one open ticket per finding
└── ledger.md              ← one line per closed ticket, written by doc-review-fix
```

Number tickets from `01`, continuing past the highest number across `issues/` *and* `ledger.md` so a number is never reused:

```
# 12 — duplicated — docs/setup.md:12 ↔ README.md:40
Found: 2026-10-05 @ abc1234, scope: full
Fix: auto

## Evidence
Both define the install flow; README's copy already drifted on the flag name.

## Proposed fix
Keep docs/setup.md canonical; README links to it.
```

`scope:` records what was actually swept — `full`, or the resolved file paths, never the literal `session` (the session is gone by the time anyone reads the stamp) — so a later re-gather can replay it.

`Fix:` marks who can decide:

- `auto` — the correction follows from the evidence alone: code is the oracle (wrong, orphaned), the copies still agree (duplicated), the right home is obvious (misplaced).
- `ask` — the fix needs a human ruling: which side is true (contradictory, or wrong with no oracle in the repo), what fills the gap (incomplete), which reading was meant (ambiguous), whether it earns its load (noise).

Dedup before filing — check the open tickets and the ledger:

- Defect already open as a ticket → file nothing new. Touch the existing ticket only when the re-find adds genuinely new information — update its evidence in place.
- Defect matching a `wontfix` ledger line → leave it; the user re-enables it by deleting the line.
- Defect matching a `fixed` ledger line → file it fresh: that's a regression worth seeing.

A clean sweep files nothing. End the reply with per-category counts of tickets filed, plus the open-ticket total.
