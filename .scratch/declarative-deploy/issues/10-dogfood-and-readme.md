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

**Status:** ready-for-agent

- [ ] This repo has a tracked, converged Intent; check mode reports clean in a fresh session
- [ ] The tracked-Intent branch is thereby exercised in real use (exclude rule correctly skipped)
- [ ] README distribution-model section describes Intent, Apply, the skill, and the staleness hook using glossary vocabulary
- [ ] References to the retired per-hook enable flow are gone from README and CLAUDE.md
- [ ] Migration note for other Subscribers recorded (one Setup conversation each; no synthesis from residue)
