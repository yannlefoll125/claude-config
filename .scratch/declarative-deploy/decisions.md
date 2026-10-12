# Declarative deploy — grilling decisions (2026-10-12)

Reorganization of configuration + updates around a decide/apply split with a per-Target
Intent file. Grilled via /grill-with-docs, walked with /one-by-one. Terms adopted into
CONTEXT.md (Intent, Apply, Managed Block; Setup redefined).

1. **Intent scope — full.** The Intent file records *everything* Setup decides (base
   settings, hooks, plugins, Managed Blocks). `settings.local.json` becomes pure Apply
   output. Policies, never outcomes: e.g. `permissionMode: "auto-if-virtualised"` is
   evaluated at Apply time (the virtualisation gate moves to Apply; same for the
   absolute statusline path).
2. **Intent git status — per-project, no requirement.** The machinery must handle both
   tracked and excluded; Setup adds it to `.git/info/exclude` only when not already
   tracked. Nothing may assume either state.
3. **Install runs Apply — auto-run, conservative.** `claude-config-install` (and
   therefore Push) ends by running the Target's own Apply copy. Apply converges only
   untracked state; drift in tracked files is *reported*, never silently written.
4. **Managed markers — adopted everywhere.** All suite-written markdown (CLAUDE.md
   blocks, docs/agents seeds) is wrapped in `claude-config:begin/end` markers with a
   payload hash (whole seeded files: hash header). Refresh is mechanical; LLM only does
   initial placement/merge.
5. **Removal — stateless heuristics, no applied-state file.** Ownership inferred:
   hook symlinks resolving into `.claude/scripts/git-hooks` are ours; settings keys from
   a fixed known set; MD blocks by marker presence. Consequence: plugin *disable* cannot
   be automatic (hand-installed vs ours is indistinguishable) — Apply reports it for
   manual action.
6. **Skill shape — separate, intent-driven.** `install-mattpocock` survives as its own
   skill but reads its answers (tracker, labels, overlays) from the Intent file instead
   of inline standard answers; Setup chains into it.
7. **Migration — no-op + report.** Apply in a Target without an Intent file touches
   nothing and prints a pointer to `/setup-claude-config`. No synthesis of intent from
   observed state.
8. **Format — JSON.** jq is already the tool for the settings merge; no new
   dependencies. No comments in the file, accepted.
9. **Vocabulary — adopted as amended.** Terms: Intent / Apply / Managed Block; Setup
   redefined as the decide step. The file is `.claude/claude-config.json` — the glossary
   term carries the policy/residue distinction, the filename stays plain (nothing to
   disambiguate against; sole sibling is the machine-written `.claude-config-manifest`).

## Follow-ups noted during the walk

- ADR needed: decide/apply split supersedes ADR-0005 ("setup is prompt-driven, no
  script") — the deterministic writer it rejected returns, split at decide/apply.
- ADR-0006 (virtualisation gate) is affected: the gate's *evaluation* moves from Setup
  to Apply time (decision 1).
- Apply ships in the Payload (fact-forced: the Config Repo is not mounted in a consuming
  Sandbox — ADR-0004), so Install invokes the Target's own copy.
- `scripts/git-hooks/enable` is absorbed by Apply.

## Amendments from /to-tickets review (2026-10-12)

User surfaced that Apply is dual-environment (Host via Push, Sandbox via Setup) while its
outputs are shared by both. Three rules added to the spec:

- **Monotone env-dependent writes**: Apply writes an environment-dependent outcome only on
  a positive evaluation in its own environment; negative → leave existing value, report.
- **Statusline resolves at render time**: the persisted command reads
  `workspace.project_dir` from the statusline's documented stdin JSON (verified: cwd and
  CLAUDE_PROJECT_DIR are *undocumented* for statusLine; stdin is the only documented
  env-agnostic source). No absolute path persisted; amends ADR-0004's consequence.
- **Plugins are split-scope**: settings entry shared/declarative; plugin cache per-home,
  converged per environment by whichever Apply runs there.

**Decision 3 revised (user, same review)**: Install/Push never run Apply — "apply on push"
dropped as unnecessarily complicated. Apply runs in-session only: a thin skill runs it in
the session's own environment (Host or Sandbox alike), and a SessionStart hook — itself a
settings key Apply converges, using the hooks-documented project-dir variable — runs
Apply's read-only check mode and suggests the skill on drift. Install and Push stay pure
file copies (installer untouched by this effort). Echoes archived ADR-0007's staleness
hook, reborn project-locally. The conservative tracked-file rule stays regardless of
caller.
