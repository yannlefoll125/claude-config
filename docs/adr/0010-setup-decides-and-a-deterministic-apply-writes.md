---
status: accepted
---

# Setup decides, and a deterministic Apply writes

Supersedes [ADR-0005](./0005-setup-is-prompt-driven.md). Configuring a Target is split in
two. **Setup** stays a prompt-driven conversation: it explores the Target, recommends,
confirms, and records every choice as the Target's **Intent** (`.claude/claude-config.json`).
**Apply** is a deterministic Payload script that converges the Target to that Intent —
settings keys, hook symlinks, plugin installs — and reports drift in tracked files, such
as a stale **Managed Block**, rather than writing it. Setup runs Apply after writing the
Intent, and keeps only the placement an agent is genuinely needed for.

Apply runs in-session only — from Setup, or from a thin skill — so it always evaluates
policies in the environment whose session consumes them. Install and Push stay pure file
copies. A SessionStart hook, itself a settings key Apply converges, runs Apply's
read-only check and suggests the skill on drift.

## Why this is not the script ADR-0005 rejected

ADR-0005 rejected a script that *decided* what it could and handed the rest to the agent
in a report. Its payoff was unattended operation, which a present human made worthless.
Here the script decides nothing: the human decides once, in conversation, and the Intent
carries the answer. What the script buys is not unattendedness but what prose cannot give
— a record of what is on, idempotent re-runs, mechanical refresh, detectable drift, and
removal by editing one file.

Prompt-driven correctness is retained for the decide step only. Exploring an unfamiliar
Target and merging prose into existing files still need an agent, and those rules stay
precisely written prose. Everything mechanical leaves the prose, so two sessions given the
same choices produce identically configured Targets — the failure ADR-0005's second
rejected option named.

## Considered Options

- **Keeping Setup the only writer** (ADR-0005 as it stood) — rejected. Each feature left
  its state as residue in a different place, so nothing recorded intent: no declarative
  enable or disable, no overview, and Push left settings, hooks, plugins and suite-written
  markdown to rot invisibly.
- **Install and Push running Apply** after copying — rejected. A Push from the Host would
  evaluate environment-dependent policy on the Host for a Target consumed in a Sandbox,
  and the extra machinery bought nothing the in-session hook does not.
- **An applied-state record** for removal — rejected in favour of stateless ownership
  heuristics: hook symlinks resolving into the Payload's hooks directory, a fixed set of
  settings keys, Managed Block markers. The price is that a dropped plugin is reported,
  never uninstalled — a hand-installed plugin is indistinguishable from the suite's.
- **Synthesising an Intent from observed residue** for existing Targets — rejected as
  guesswork. Apply without an Intent touches nothing and points at Setup.
- **Recording outcomes** (e.g. "auto mode on") rather than policies — rejected. The same
  Intent must hold on the Host and in a Sandbox, so environment-dependent choices are
  stored as policy and evaluated at Apply time
  ([ADR-0006](./0006-auto-permission-mode-gated-by-virtualisation.md)).

## Consequences

Apply is still dual-environment: sessions happen on the Host as well as in a Sandbox, and
everything it writes is shared by both. Environment-dependent writes are therefore
monotone — written only on a positive evaluation, never stripped on a negative one — and
the statusline resolves its script at render time
([ADR-0004](./0004-setup-deploys-project-local-and-leaves-no-git-trace.md)). Plugins are
split-scope: the settings entry is shared, the cache is per-home, and each environment's
own Apply run converges its cache.

Apply never silently edits tracked files, so whoever keeps a Managed Block current does it
by an explicit refresh. Every existing Subscriber needs one Setup conversation to gain an
Intent.

Apply is the repo's first code with real logic, so it gets tests at its CLI seam; Setup
does not.
