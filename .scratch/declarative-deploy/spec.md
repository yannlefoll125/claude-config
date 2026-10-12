# Spec: Declarative deploy — Intent file and decide/apply split

Status: ready-for-agent

## Problem Statement

Configuring a Target is heteroclite: every feature stores its "enabled" state in a
different place, in whatever form the enabling mechanism happens to leave behind —
settings keys written by a prompt-driven skill, git-hook symlinks created by a
per-feature enable script, plugin entries, and LLM-edited prose in tracked markdown.
There is no record of *intent*, only residue. Consequently there is no declarative way to
enable or disable a feature, no way to see what a project has turned on, and the updates
story covers only Payload files: a Push refreshes copies but leaves settings, hooks,
plugins, and suite-written markdown to rot invisibly.

## Solution

Split *deciding* from *applying*. Each Target gets an **Intent** — a declarative JSON
file, `claude-config.json` in the Target's `.claude` directory — recording every choice
Setup made: which features are on, with which options, as policies rather than
environment outcomes. A deterministic **Apply** script, shipped in the Payload, converges
the Target to its Intent: merges settings keys, manages hook symlinks, installs plugins,
and checks suite-written markdown. Apply runs in-session only, invoked by a thin skill
(and by Setup), so it always evaluates policies in the environment whose session consumes
them; Install and Push remain pure file copies. A SessionStart hook — itself a settings
key Apply converges — runs Apply's read-only check mode and points at the skill when the
Target has drifted, so configuration Staleness surfaces exactly where it matters: at the
start of a session.
Suite-written prose in tracked files becomes **Managed Blocks** — marker-wrapped,
hash-stamped — so drift is detectable and refresh mechanical. Setup shrinks to the decide
step: explore the Target, converse, write the Intent, run Apply, and do only the
placement an agent is genuinely needed for.

## User Stories

1. As a config consumer, I want every enabled feature of a project recorded in one declarative file, so that I can see what is configured at a glance.
2. As a config consumer, I want to enable or disable a feature by editing the Intent and re-running Apply, so that configuration changes stop requiring bespoke per-feature tools.
3. As a config consumer, I want each session to tell me at start when the Target's configuration has drifted from its Intent, so that Staleness surfaces exactly where it matters.
4. As a config consumer, I want the Intent to record policies instead of outcomes, so that the same file is valid on the Host and in a Sandbox.
5. As a config consumer, I want the virtualisation gate evaluated at Apply time, so that an Intent written in a Sandbox never forces auto permission mode on the Host.
6. As a config consumer, I want to decide per project whether the Intent is tracked or excluded, so that personal configuration stays out of shared repos while my own repos can self-describe.
7. As a config consumer with a tracked Intent, I want a fresh clone to converge with a single Apply after Install, so that new environments need no Setup conversation.
8. As an agent running Setup, I want to record decisions in the Intent and delegate all mechanics to Apply, so that two sessions produce identically configured Targets from the same choices.
9. As an agent in a Target, I want Apply to be idempotent, so that re-running it is always safe.
10. As a config consumer, I want Apply to write only untracked state and never silently edit tracked files, so that no run ever leaves surprise diffs in tracked markdown.
11. As a config consumer, I want drift in Managed Blocks reported with the exact step that refreshes them, so that tracked-file Staleness is visible instead of silent.
12. As a config consumer, I want all suite-written markdown wrapped in hash-stamped markers, so that what the suite owns is distinguishable from what humans wrote.
13. As a project collaborator, I want hand-written content outside the markers left untouched by refresh, so that the suite never clobbers project documentation.
14. As a config consumer, I want to fork a Managed Block by deleting its markers, so that I can deliberately diverge from the shipped prose without fighting the updater.
15. As a config consumer, I want git-hook enablement driven by the Intent, so that hook state is reproducible instead of per-clone folklore.
16. As a config consumer, I want Apply to remove a dropped hook's symlink only when it resolves into the Payload's hooks directory, so that a project's own hooks are never touched.
17. As a config consumer, I want plugin enablement driven by the Intent, so that the plugin set is part of the declared configuration.
18. As a config consumer, I want Apply to report — not uninstall — a plugin the Intent dropped, so that a hand-installed plugin is never removed on a heuristic.
19. As an agent running the mattpocock install, I want its answers read from the Intent, so that there is a single source of truth for its options.
20. As a config consumer migrating existing Subscribers, I want Apply without an Intent to be a no-op with a pointer to Setup, so that no existing Target is mutated by guesswork.
21. As an agent, I want Apply to report each action in one line (done, skipped and why, or drift found), so that the session can relay outcomes truthfully.
22. As the config author, I want Apply to manage only its known settings keys, so that a Target's other settings survive convergence untouched.
23. As the config author, I want automated tests at the executables' CLI seam, so that installer and Apply changes are verified before any Push.
24. As the config author, I want the per-hook enable script absorbed into Apply, so that there is one entry point for all state changes.
25. As a teammate reading a tracked Intent, I want it to document which agent tooling the project uses, so that the file doubles as onboarding material.
26. As a config consumer, I want a skill that runs Apply in the session's own environment, so that convergence never depends on which environment a Push happened to run from.
27. As a config consumer, I want the staleness hook itself converged from the Intent like any other settings key, so that the detection machinery needs no separate installation step.

## Implementation Decisions

Decisions below were settled in the grilling recorded in the decision log beside this
spec; the glossary terms (Intent, Apply, Managed Block, redefined Setup) are already in
the Config Repo's CONTEXT.md.

- **Intent is full-scope**: it records everything Setup decides — base settings (model,
  notifications, permission-mode policy, statusline), git hooks, plugin set, and the
  options feeding Managed Blocks. The Target's local settings file becomes pure Apply
  output for the keys Apply owns.
- **Policies, never outcomes**: environment-dependent choices are stored as policy
  (e.g. permission mode "auto-if-virtualised") and evaluated by Apply at run time; the
  virtualisation detection moves from Setup into Apply.
- **Apply is still dual-environment**: running in-session makes the evaluating
  environment the consuming one by construction, but sessions can happen on the Host as
  well as in a Sandbox, and everything Apply writes is shared by both — the same working
  tree mounted at different absolute paths. Outcomes must therefore stay valid for
  sessions in either environment:
  - *Monotone environment-dependent writes*: an environment-dependent policy is written
    only when Apply's own environment evaluates it positively; a negative evaluation
    leaves any existing value untouched and reports it one-line style. A Host session's
    Apply run thus never strips the auto permission mode a Sandbox session relies on.
  - *Statusline resolves at render time*: Apply writes a command string that reads the
    statusline's stdin JSON and invokes the Target's deployed script via the documented
    `workspace.project_dir` field — no absolute path is persisted, making the key
    environment-independent. (The statusline command's working directory and hook-style
    env vars are undocumented, so the stdin JSON is the only documented
    environment-agnostic source. This amends ADR-0004's consequence about
    `statusLine.command`.)
  - *Plugins are split-scope*: the project-scope settings entry is shared and
    declarative; the plugin cache lives in each environment's home. Apply converges the
    entry wherever it runs, performs the CLI install when the CLI is available, and
    reports that cache convergence is per-environment — each environment's own in-session
    Apply run (prompted by the staleness hook) converges its cache.
- **Intent format and name**: JSON (jq is the parser Apply already needs; no new
  dependencies), named `claude-config.json`, living beside the Manifest. The glossary
  term carries the policy/residue distinction; the filename stays plain.
- **Git status is per-project**: the machinery must handle a tracked and an excluded
  Intent equally. Setup adds it to the clone-local git exclude only when it is not
  already tracked; nothing downstream may assume either state.
- **Apply ships in the Payload**: the Config Repo is not mounted in a consuming Sandbox
  (ADR-0004), and Setup must invoke Apply in-session, so Apply is an Artifact. Install
  invokes the Target's freshly copied Apply after the copy step.
- **Apply runs in-session only**: Install and Push stay pure file copies and never invoke
  Apply. The in-session entry points are a thin skill that runs the Target's Apply and
  relays its report, and Setup (which invokes Apply after writing the Intent). Apply
  stays conservative regardless of caller: it converges untracked state only — settings
  keys, hook symlinks, plugin installs — and *reports* drift in tracked files; refreshing
  Managed Blocks is a separate explicit invocation (a flag on Apply) or done in-session.
- **A SessionStart hook surfaces drift**: Apply owns a read-only check mode that compares
  the Target against its Intent (and the Manifest stamp against the installed Payload)
  and exits distinctly when drift exists. The hook — itself one of the settings keys
  Apply converges from the Intent, on by default — runs the check at session start via
  the documented project-dir variable for hook commands and suggests the skill when the
  check reports drift. With no Intent present it stays silent beyond the pointer to
  Setup.
- **Removal is stateless**: no applied-state record. Ownership is inferred — a hook
  symlink is the suite's when it resolves into the Payload's hooks directory; settings
  keys come from a fixed known set; Managed Blocks are identified by their markers.
  Plugins have no safe heuristic, so a dropped plugin is reported for manual removal,
  never uninstalled.
- **Managed Blocks everywhere**: every piece of suite-written markdown in tracked files
  is wrapped in begin/end comment markers stamped with a content hash; whole seeded files
  carry a hash header instead. Refresh replaces marker contents mechanically. The LLM is
  needed once per file, for placement and merging; afterwards hand-edits inside markers
  are overwritten on refresh, and deleting the markers forks the block out of management.
- **Setup is the decide step**: it explores the Target, converses, writes the Intent,
  runs Apply, then performs agent-only placement. The existing prose idempotency rules
  shrink accordingly.
- **The mattpocock skill survives, intent-driven**: it stays a separate skill but reads
  its answers (tracker flavor, triage labels, overlays) from the Intent rather than
  carrying inline standard answers; Setup chains into it as today.
- **Migration**: Apply in a Target with no Intent touches nothing and points at Setup.
  Existing Subscribers each need one Setup conversation; no synthesis of Intent from
  observed residue.
- **The per-hook enable script is absorbed** into Apply (same symlink mechanics,
  including the relative-path rule from ADR-0009).
- **ADR follow-ups**: a new ADR supersedes ADR-0005 (a deterministic writer returns,
  split at decide/apply rather than script-plus-report); ADR-0006 is amended to note the
  gate's evaluation moved to Apply time and is monotone across environments. ADR-0004's
  no-git-trace stance is unchanged but gains the per-project Intent exception at the
  user's discretion, and its `statusLine.command` consequence is amended to the
  render-time stdin resolution.

## Testing Decisions

- **One seam, the CLI boundary**: tests invoke the real executables — the installer and
  the Target's Apply — against a temporary git repository acting as a Target, and assert
  only external behavior: exit code, the one-line-per-action report on stdout, and the
  resulting filesystem (settings keys via jq, symlink presence and resolution, Manifest
  contents, exclude entries, marker hashes). No test reaches into the scripts' internals.
- **Externals stubbed via PATH**: the `claude` CLI (plugin installs, model probe) and
  `systemd-detect-virt` are faked by prepending a fake-bin directory to PATH in tests;
  the scripts themselves carry no test hooks. Both gate outcomes (virtualised and not)
  are exercised this way.
- **Scenarios to cover**: fresh Install with no Intent (no-op + pointer); Intent with
  each feature on and off; re-run idempotency (second Apply changes nothing); disable
  removes the suite's hook symlink but refuses a foreign one; dropped plugin is reported,
  not uninstalled; unknown settings keys survive; Managed Block drift detected and
  reported but not written; explicit refresh rewrites only marker contents; tracked
  versus excluded Intent both work; dual-environment sequences — a non-virtualised
  (Host-like) Apply run after a virtualised one preserves environment-dependent keys,
  and the written statusline command resolves the deployed script correctly when fed
  mock stdin JSON carrying two different absolute mount paths; check mode is read-only
  (changes nothing on disk), exits distinctly on drift versus clean versus no-Intent, and
  its one-line output names the skill to run.
- **Prior art**: none — these are the repo's first automated tests. They live outside the
  Payload (tooling, never shipped) and run from the Makefile.
- The prompt-driven skills (Setup, the mattpocock install) get no code-level tests; their
  correctness remains precisely-written prose rules per ADR-0005's consequence, which the
  superseding ADR preserves for the decide step.

## Out of Scope

- The Config Plugin distribution vector (loading Artifacts in place) — the copy-based
  model stays.
- Synthesizing an Intent from a Target's observed state.
- An applied-state record (rejected in favor of stateless heuristics).
- Automatic plugin uninstall.
- Any change to Push's human-only convention or to the no-credential Sandbox rules
  (ADR-0008).
- Multi-hook dispatch directories for colliding git hooks — current collision behavior
  (refuse and explain) stays.
- Automated testing of prompt-driven skills.

## Further Notes

- The full decision log, including the grilling's question-by-question record, is in
  `decisions.md` beside this spec.
- The Config Repo is a Target of its own Payload, so it is also the first migration case:
  its own Intent should be written as part of implementation (and, being the author's own
  repo, is a natural candidate for a *tracked* Intent, exercising that branch).
- Apply's report style should follow the suite's existing convention: one line per step,
  stating done / skipped-with-reason / drift-found.
