---
status: accepted
---

# `/setup` enables auto permission mode, gated by virtualisation detection

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
