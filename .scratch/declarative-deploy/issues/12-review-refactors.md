# 12: Review follow-up — apply-internal refactor candidates

**What to build:** Judgement-call smells from the standards review (2026-10-12), all in
`scripts/apply`, all behavior-neutral:

1. *Duplicated converge/check shape*: `converge_model` / `converge_notifications` /
   `converge_statusline` (and their `check_*`) repeat one shape four times — read Intent
   key → `settings_get` → compare → `settings_set`/`settings_del` → report. A
   table-driven owned-key helper would collapse them.
2. *Redundant drift flags*: `stale` and `manual` (`drift_manual`) have identical
   semantics ("drift converging can't cure") and identical effect on the exit line —
   merge into one flag.
3. *Primitive obsession, minor*: `"<plugin>@<marketplace>"` strings are re-split with
   `${p#*@}` / `${p%@*}` at each consumer; tolerable in bash, noted only.

Touches many lines plus wording-sensitive tests; batch the three together if done.

**Blocked by:** None.

**Status:** needs-triage

- [ ] One shared helper drives the four settings concerns
- [ ] One flag replaces stale/manual
- [ ] Report wording unchanged (or tests updated deliberately); `make test` green
