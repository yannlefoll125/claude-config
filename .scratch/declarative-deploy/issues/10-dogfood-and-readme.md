# 10: Dogfood migration and README

**What to build:** The Config Repo, as a Target of its own Payload, becomes the first
migration case: a Setup conversation writes its Intent — tracked, exercising that branch
of the per-project rule — and Apply converges it; the session-start hook then reports
clean. The README's distribution-model section is rewritten for the new story: configure
by editing the Intent (or running Setup) and letting the in-session skill converge;
updates surface via the session-start staleness check; Install and Push are unchanged
pure file copies. CLAUDE.md's repo instructions are updated where they reference the
retired enable-script flow.

**Blocked by:** 08 (Setup decide step), 09 (install-mattpocock intent-driven).

**Status:** ready-for-human

- [x] This repo has a tracked, converged Intent; check mode reports clean in a fresh session
- [x] The tracked-Intent branch is thereby exercised in real use (exclude rule correctly skipped)
- [x] README distribution-model section describes Intent, Apply, the skill, and the staleness hook using glossary vocabulary
- [x] References to the retired per-hook enable flow are gone from README and CLAUDE.md
- [x] Migration note for other Subscribers recorded (one Setup conversation each; no synthesis from residue)

Notes: the Intent's `gitHooks` is `[]`, mirroring what was armed (nothing). In
`.claude/CLAUDE.md` the existing agent-skills and main-flow-handback sections were wrapped
and stamped as Managed Blocks (their prose is what the machinery produces), and the
`claude-config` block was appended; the three `docs/agents/*.md` files stay forked — they
predate seed headers and diverge from the current plugin templates. The migration note
lives in the README under "Migrating an existing subscriber".
