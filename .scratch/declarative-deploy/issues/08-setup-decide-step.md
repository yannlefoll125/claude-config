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

**Status:** ready-for-human

- [x] Setup writes a valid full-scope Intent (policies, never outcomes) and invokes Apply for every mechanical step
- [x] Tracked-versus-excluded handled per the rule; neither state is assumed anywhere
- [x] Ad-hoc argument overrides still work, now landing in the Intent instead of one-off actions
- [x] Re-running Setup is safe: it updates the Intent and re-converges, never duplicates
- [x] Skill prose contains no step Apply can perform; rules are specific enough to verify
- [x] End-to-end demo in a scratch project: fresh Install → Setup → converged Target, hook silent on next session

**Notes:** Skill prose is `skills/setup-claude-config/SKILL.md` (the `.claude/` copy syncs
at commit). It points at the `scripts/apply` header for the authoritative key list and
writes every key explicitly (notably `statusline: true`, whose Apply default is false).
Setup places only block `claude-config` (first of `CLAUDE.md`, `.claude/CLAUDE.md`,
`AGENTS.md`, else a new root `CLAUDE.md`), copying it with the shell and stamping
`awk 1 src | sha256sum | cut -c1-12`; existing markers mean "already placed", the bare
heading means "forked". The plugin list carries `mattpocock-skills@claude-plugins-official`
so Apply installs it; the install-mattpocock chain is unchanged (ticket 09). Demo run in
a scratch repo under `$HOME`: excluded branch appended `/.claude/claude-config.json` to
`.git/info/exclude`; Apply exit 0 converging all eight concerns; re-run all `skipped`;
`apply --check` exit 0 and silent; the SessionStart hook command ran silent; an override
re-run and the tracked branch both re-converged clean. No Apply changes were needed.
