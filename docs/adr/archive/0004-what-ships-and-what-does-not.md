---
status: accepted
---

# Only `dist/` ships, and `/setup` targets `~/.claude` by default

`dist/` is the Payload: the Config Plugin's root and the files `/setup` deploys from. `.claude-plugin/marketplace.json` sits at the **repo root** and points at it with `"source": "./dist"` — a git-based marketplace clones the whole repository, so a relative source resolves. Everything else in the Config Repo — `marketplace/`, `tools/`, `docs/`, `CONTEXT.md`, `.claude/` — is service, tooling or documentation and is never installed into a Sandbox. `/setup` writes to `~/.claude` by default so preferences apply in every folder of a Sandbox, honours an existing project-local preference when it finds one, and always offers the choice.

## What ships, and how

Artifacts fall in two groups, and the split is forced by what a plugin can express:

- **Loaded in place** by the plugin mechanism: skills, agents, output styles. No deploy step, and they update with the plugin.
- **Deployed by `/setup`**, because no plugin can express them: `statusline.sh`, settings keys (`outputStyle`, `statusLine`, permissions), and memories. A plugin's own `settings.json` supports only the `agent` and `subagentStatusLine` keys, so the main statusline must be written into the user's settings.

`statusline.sh` is copied to `~/.claude/scripts/` and `statusLine.command` points at that copy. It must never point at the Config Repo or into the plugin cache: the repo is not mounted in a consuming Sandbox at all, and the cache path is version-pinned and re-cloned on update. Getting this wrong — `settings.json` pointing at `/workspace/scripts/statusline.sh` — is what first exposed the source-versus-deployed-copy distinction.

## Memories

Only **cross-project** memories ship, in `dist/memories/`, seeded by `/setup` into the memory directory of the project being set up. Project-specific memories are written where they are learned and never ship.

The reason is that memory is stored per project, under `~/.claude/projects/<project-slug>/memory/`, keyed by a slug derived from the project path. There is no user-wide memory location to seed, so shipping everything would mean injecting one project's context into every other project.

## Consequences

Adding a preference means asking which group it falls in. If a plugin can carry it, put it in `dist/` and let the plugin mechanism do the work; only reach for a `/setup` deploy step when the plugin system genuinely cannot express it.
