---
status: superseded by ADR-0003
---

# One repo is the marketplace, the Entry Point Plugin, and the artifact source

> **Superseded by [ADR-0003](./0003-vendored-local-marketplace.md).** The single-repo conclusion still holds, but delivery no longer happens by cloning a private remote marketplace — a pinned copy is vendored into the target project instead, so a Sandbox needs no credential. The two traps recorded below apply only to the remote-marketplace route and are no longer live.


The Config Repo plays three roles at once: it hosts `.claude-plugin/marketplace.json`, it is the source of a deliberately thin Entry Point Plugin carrying only a setup skill, and it holds every Artifact. Claude Code supports private-repo marketplaces over HTTPS through ordinary git credential helpers, so the private GitHub repo needs no additional hosting to be distributable. The setup skill takes its own `git clone` to a stable path (the Working Clone) and deploys from there.

## Considered Options

- **Deploy straight from the plugin cache** (`${CLAUDE_PLUGIN_ROOT}`) — rejected. Installing a plugin whose source is `./` clones the whole repo, so the Artifacts genuinely are already on disk and this would cost nothing. But the cache path is version-pinned (`.../<plugin>/<version>/`) and Claude Code deletes and re-clones it on update, so round-trip edits made there would be lost.
- **Two repos, a thin public bootstrapper plus a private artifact repo** — rejected as two things to maintain, for no gain: the setup skill needs the PAT to reach the private repo either way.

## Consequences

Two known traps, both from the plugin docs:

- A `owner/repo` shorthand marketplace source **clones over SSH by default**. There is no SSH key in a fresh Sandbox, so use the full HTTPS URL or set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`.
- The background marketplace refresh **disables git credential helpers**, so a private HTTPS marketplace cannot auto-update and falls back to deleting and re-cloning. Set `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` so a failed pull keeps the last good clone.

The plugin cache and the Working Clone are two checkouts of the same repo at possibly different commits. The Working Clone is authoritative for editing; the cache is delivery only.
