# 08: Setup rewritten as the decide step

**What to build:** The Setup skill becomes the decide step and nothing else: explore the
Target, converse where the arguments don't already answer, write the choices into the
Intent as policies (handling the per-project tracked-versus-excluded rule: add the Intent
to the clone-local git exclude only when it is not already tracked), run Apply, relay its
report, and finish with the placement only an agent can do — merging Managed Blocks into
existing files. All mechanics the old skill performed itself (settings writes,
virtualisation detection, statusline wiring) are gone from the prose: Apply owns them.
Prose-verified per the superseding ADR; demoable end-to-end in a scratch project.

**Blocked by:** 04 (settings), 05 (git hooks), 06 (plugins), 07 (Managed Blocks).

**Status:** ready-for-agent

- [ ] Setup writes a valid full-scope Intent (policies, never outcomes) and invokes Apply for every mechanical step
- [ ] Tracked-versus-excluded handled per the rule; neither state is assumed anywhere
- [ ] Ad-hoc argument overrides still work, now landing in the Intent instead of one-off actions
- [ ] Re-running Setup is safe: it updates the Intent and re-converges, never duplicates
- [ ] Skill prose contains no step Apply can perform; rules are specific enough to verify
- [ ] End-to-end demo in a scratch project: fresh Install → Setup → converged Target, hook silent on next session
