---
status: accepted — amended by ADR-0010
---

# `/setup` enables auto permission mode, gated by virtualisation detection

> **Amended by [ADR-0010](./0010-setup-decides-and-a-deterministic-apply-writes.md)** — see [Amendment](#amendment-apply-time-monotone-evaluation) below. The gate is now evaluated by Apply, not Setup.

Rather than shipping a curated allowlist of safe commands, `/setup` sets
`permissions.mode: "auto"` in the Target's `.claude/settings.local.json`. Auto mode
classifies each call instead of skipping the check, which suits a Sandbox where the
isolation boundary — not the prompt — is what actually contains the agent.

`/setup` detects virtualisation before offering it:

- **Virtualised** — auto mode is the recommended default, accepted in one word.
- **Not virtualised** — auto mode is off by default and `/setup` says why. The user can
  still enable it, but must say so explicitly.

Detection is `systemd-detect-virt`, falling back to `/run/.containerenv` (podman),
`/.dockerenv` (docker), the `$container` environment variable, and
`/sys/class/dmi/id/sys_vendor`. It deliberately answers only "virtualised, yes or no" and
never branches on which backend.

## Considered Options

- **A read-only command allowlist** (`ls`, `git status`, `grep`, …) — rejected as largely
  redundant once auto mode is on, and it would auto-grant in whatever repository `/setup`
  ran in.
- **`bypassPermissions`** — rejected. It skips the check entirely rather than classifying,
  and buys nothing over auto mode inside a Sandbox.
- **A hard block on bare metal** — rejected. A mis-detected hypervisor would lock the user
  out of the main feature with no way round it from inside the tool.

## Consequences

**Detection proves virtualisation, not disposability.** Someone's daily-driver Linux VM is
indistinguishable from a throwaway Sandbox. The gate is advice with an escape hatch, not a
guarantee — the real boundary remains the Sandbox itself.

Because settings are project-local
([ADR-0004](./0004-setup-deploys-project-local-and-leaves-no-git-trace.md)), auto mode
applies only where `/setup` ran, not machine-wide.

## Amendment: Apply-time, monotone evaluation

Setup no longer evaluates the gate. It records a policy in the Intent
(`"auto-if-virtualised"`), and Apply evaluates it each time it runs, in the environment of
the session that runs it. The detection chain above is unchanged; only its caller moved.

Evaluation is monotone across environments. Host and Sandbox share the same
`settings.local.json`, so a positive evaluation writes auto mode, and a negative one never
strips an existing value — it leaves it and reports one line saying so. A Host session's
Apply run therefore cannot remove the auto mode a Sandbox session relies on. Turning auto
mode off is an Intent edit, not a side effect of where Apply last ran.
