---
status: accepted
---

# `dist/` is the plugin root, and `dist/deploy/` holds what a plugin cannot carry

`dist/` is the Payload and the Config Plugin's root at the same time:
`.claude-plugin/plugin.json`, `skills/`, `hooks/`, `output-styles/`. Deployed Artifacts
live in `dist/deploy/`. The plugin mechanism ignores that directory, but the marketplace
clone brings it along, so `/setup` reads it at `${CLAUDE_PLUGIN_ROOT}/deploy/`.

## Considered Options

- **`dist/plugin/` and `dist/deploy/` as siblings** — rejected. Conceptually tidier, since
  the two Artifact kinds are peers, but it costs a path level everywhere and stops "the
  Payload" and "the Config Plugin" being the same thing.

## Consequences

One rule covers what ships: **if it is not in `dist/`, it does not reach a Sandbox.**
Everything else in the repo — `docs/`, `CONTEXT.md`, CI config — is documentation or
tooling.

Adding a preference means asking which kind it is. If the plugin can express it, it is a
Carried Artifact and needs no code. Only reach for `dist/deploy/` when the plugin system
genuinely cannot express it.
