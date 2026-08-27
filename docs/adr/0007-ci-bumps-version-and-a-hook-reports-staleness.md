---
status: accepted
---

# CI bumps the version, and a SessionStart hook reports Staleness

The version is `0.y.z`. A GitHub Action bumps `y` in `dist/.claude-plugin/plugin.json` on
push, whenever `dist/` changed, and commits the bump back with `[skip ci]`.

Separately, `/setup` writes a version stamp into the Target when it deploys. A SessionStart
hook in the Payload compares that stamp against the installed Config Plugin's version and
warns when they differ.

## Why both

Both failures are silent, and silence is the failure mode worth paying to remove.

Claude Code only notices an update when `plugin.json`'s `version` changes, so a forgotten
bump means every Sandbox quietly stops receiving updates. And `/plugin update` refreshes
Carried Artifacts but never touches Deployed Artifacts, so a Target can run months-old
configuration with nothing to indicate it.

## Considered Options

- **A local git hook** in a tracked directory with `core.hooksPath` — rejected. Every
  fresh clone must run one command to arm it, and nothing complains when nobody does,
  which reintroduces exactly the silent failure the bump exists to prevent.

## Consequences

Bot commits appear in the history. The Action must skip its own commits or it loops.
