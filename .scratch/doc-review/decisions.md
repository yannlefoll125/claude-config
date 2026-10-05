# doc-review skill suite — design decisions

Grilled 2026-10-05 (`/grill-with-docs` → `/one-by-one`). Each point below is a recorded user decision.

## Idea

A skill suite to review project documentation against a nine-category defect taxonomy:
stale (code moved), incorrect (born false), orphaned (subject gone), contradictory (docs
disagree), duplicated (will diverge), incomplete (gap), ambiguous (multiple readings),
misplaced (wrong location), noise (true but useless).

## Decisions

1. **Scope — Payload.** The suite ships as Artifacts into every Target via Install. Its
   instructions must be project-agnostic: discover each Target's doc landscape, never
   assume `CONTEXT.md`, `docs/adr/`, or the issue-tracker convention exists.
2. **Shape — two skills.** `doc-review-gather` (agent-callable, produces findings) and
   `doc-review-fix` (consumes fresh findings; cold-starts by running gather itself when
   none exist — "both" is just fix invoked cold). Precedent: `commit` / `commit-plan`.
3. **Taxonomy — nine names, merged detection.** All nine categories are the reporting
   glossary. Gather detects stale+incorrect as one defect ("disagrees with code/reality")
   and labels origin only when evidence is free (e.g. cheap git blame). Contradictory and
   duplicated stay separate: their fixes differ (resolve truth vs pick a canonical home).
4. **Findings — file + reply summary.** Gather writes `.scratch/doc-review/findings.md`
   (one entry per finding: category, file:line, evidence, proposed fix) and also
   summarizes in its reply. File kept out of version control via `.git/info/exclude`
   (same mechanism as `SELF_HANDOFF.md`).
5. **Doc scope — prose docs only.** All git-tracked markdown (README, CLAUDE.md/AGENTS.md,
   CONTEXT.md, docs/**) excluding skill files (they have their own authoring discipline,
   `/writing-for-agents`) and code comments. Skip scratch/generated/vendored paths.
6. **Fix model — split.** Auto-apply evidence-backed mechanical categories (stale refs,
   orphaned, duplicated, misplaced), summarized afterward; drive judgment categories
   (incorrect, contradictory, ambiguous, incomplete, noise) through `one-by-one`, proposed
   fix as the recommended option. `one-by-one` is Payload too, so the dependency ships.
   *Refined by 14:* the shipped split is by oracle presence, not category.
7. **Scoping — scope arg + session hook.** No args = full sweep. Args = paths or
   "session" (docs related to this session's work). `/self-handoff` step 1 invokes gather
   session-scoped. Gather is model-invocable (no `disable-model-invocation`), with a
   trigger-friendly description.
8. **Names — `doc-review-gather` / `doc-review-fix`.** Sibling of the existing
   `code-review` skill family; shared stem keeps the pair discoverable.

9. **Findings header is a replayable record (added after review).** Header carries date,
   commit hash at gather time, and the scope argument verbatim. Fix gates on staleness —
   older than a week, or `git diff --name-only <header-commit>..HEAD -- '*.md'` shows doc
   changes — and on stale asks the user: re-gather (replaying the recorded scope) or work
   the file as-is. Gather fires from fix in exactly two cases: findings missing, or the
   user choosing re-gather at the gate.

10. **Findings are tickets; closures compress to a ledger (supersedes 4 and refines 9).**
    `.scratch/doc-review/issues/NN-<slug>.md` one per finding (never-reused numbering
    across issues/ and ledger), `ledger.md` one line per closure. Outcomes: fixed /
    wontfix (with reason) / obsolete (defect vanished); deferred = ticket stays open, no
    ledger line. Gather dedups against open tickets (append comment) and the ledger
    (wontfix never re-files — delete the line to re-enable; fixed re-files as regression).
    Staleness is per-ticket (`Found: date @ commit, scope`): fix verifies evidence before
    any auto apply, plus a light opening gate (newest stamp >1 week or md diff since →
    offer re-gather). The structure is defined in full in gather's SKILL.md — deliberately
    self-contained, independent of any Target's issue tracker (Payload-generic).
11. **Self-handoff wiring: gather at create, surface at continue.** Create dispatches a
    session-scoped gather as a subagent (keeps the sweep out of the strained window);
    continue lists "N doc findings pending — /doc-review-fix" among next steps. Fix stays
    user-chosen — the ratchet detects and re-offers every cycle, never self-applies.

12. **Tickets live under `.claude/doc-review/`, not `.scratch/`.** `.scratch/` is this
    repo's tracker convention and would leak into Targets; `.claude/` exists in every
    Target by construction (the skills only run where the Payload is installed), is
    agent-owned by convention, and the Manifest never deletes project-specific files in
    managed dirs. Still excluded from VC via `.git/info/exclude`. Bonus coherence: the
    doc-set discovery already drops everything under `.claude/`, so the tickets and
    ledger can never show up in their own sweep.

## Code review 2026-10-05 — rulings (applied to the SKILL.md files)

13. **Repo-independence.** Git-required is a legitimate dependency, no guard needed.
    VC exclusion goes through `$(git rev-parse --git-common-dir)/info/exclude` (worktree-
    safe) in gather *and* self-handoff. Doc discovery pathspec widened to
    `'*.md' '*.mdx' '*.rst' '*.adoc' '*.txt'` with a widen-if-needed note; fix's stale
    gate diffs the same pathspec. Self-handoff step 1's doc destinations: out of scope.
14. **Auto/ask split is by oracle presence, not category (refines 6).** `Fix: auto`
    whenever the correction follows from the evidence alone — code as oracle covers
    born-false claims too; `ask` when a human ruling is needed.
15. **Session scope is caller-supplied (refines 7 and 11).** A dispatched gather has no
    session context: self-handoff lists the session's touched files (docs and code) in
    the subagent prompt; gather's scope section says a dispatching caller must supply
    that list.
16. **Dedup never appends (supersedes 10's append clause).** Defect already open → file
    nothing; modify the existing ticket only for genuinely new information. No
    `## Comments` section; reply summary counts only tickets filed.
17. **Scope stamp is replayable (refines 9 and 10).** `scope:` records `full` or the
    resolved paths, never the literal `session`. Fix's stale gate offers three ways:
    re-gather the union of open tickets' scopes, full fresh sweep, or work as-is.

## State

- Done: `skills/doc-review-gather/SKILL.md`, `skills/doc-review-fix/SKILL.md`, and the
  session-scoped gather hook in `skills/self-handoff/SKILL.md` step 1.
- Remaining: sync `.claude/` copies via `./claude-config-install .` in the same commit
  (CLAUDE.md rule) when committing.
- The nine-category taxonomy's single source of truth is the gather SKILL.md; it was
  deliberately kept out of CONTEXT.md, which glossaries the config-repo domain, not
  doc defects.
