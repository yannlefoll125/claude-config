---
name: doc-review-fix
description: Work the doc-review ticket backlog — auto-apply the evidenced fixes, walk the judgment calls one by one. Runs doc-review-gather first when no tickets exist.
argument-hint: "scope forwarded to gather when the backlog is empty"
disable-model-invocation: true
---

Work `.claude/doc-review/issues/` down to empty. The ticket and ledger formats are defined in the sibling `doc-review-gather` skill — consult its SKILL.md when a format question comes up.

1. **Load the backlog.** List `.claude/doc-review/issues/` and announce the open count and the newest `Found:` stamp in your first line. Empty backlog → invoke the `doc-review-gather` skill, forwarding any arguments, and work what it files.
2. **Staleness gate.** When the newest `Found:` stamp is over a week old, or `git diff --name-only <that-commit>..HEAD -- '*.md' '*.mdx' '*.rst' '*.adoc' '*.txt'` (the same pathspec gather sweeps) shows doc changes since, ask the user: re-gather the backlog's territory (run gather over the union of the open tickets' `scope:` stamps), run a full fresh sweep, or work the backlog as-is.
3. **Auto pass.** For each `Fix: auto` ticket, verify the evidence still holds at the quoted location: it does → apply the fix and close the ticket as `fixed`; the defect is gone → close it as `obsolete`. Summarize what changed in a few lines.
4. **Judgment walk.** Drive the `Fix: ask` tickets through the `one-by-one` skill — each point presents the ticket's evidence with its proposed fix as the recommended option. Map the decision: a chosen fix → apply and close `fixed`; "it's fine as it is" → close `wontfix`, recording the reason; "not now" → defer: the ticket stays open, untouched, and resurfaces next cycle.
5. **Close out.** Closing a ticket means appending one ledger line to `.claude/doc-review/ledger.md` — `NN <category> <files> — fixed|wontfix|obsolete <date> @ <commit>[ — reason]` — and deleting the ticket file.

Done when every open ticket is either closed to the ledger or explicitly deferred.
