---
status: superseded by ADR-0005
---

# Config is delivered by a vendored local marketplace, not a private remote one

> **Superseded by [ADR-0005](./0005-host-served-git-marketplace.md).** Vendoring is dropped: a Sandbox holding only a read-only copy could never self-update, so delivery moved to a git server on the Host. The credential-free principle established here survives unchanged — it is what ADR-0005 preserves.

A script in the Config Repo, run on the Host, copies a pinned version of the repo into a target project as `.marketplace/` and registers it as a local marketplace. A Sandbox that mounts the project therefore receives the marketplace for free, and `/plugin install claude-config@claude-config` needs no credential at all.

This supersedes [ADR-0002](./0002-one-repo-marketplace-plugin-and-artifacts.md), which had Claude Code clone a private remote marketplace over HTTPS.

## Why this is better

It splits reading from writing. Installing config requires no GitHub credential in the Sandbox, so the chicken-and-egg problem that ADR-0002 worked around simply does not arise. A PAT is needed only on the Host, and only for authoring.

It also makes a project's Claude setup reproducible: `.marketplace` holds a chosen version, and it is upgraded deliberately by re-running the script.

## Consequences

- **`.marketplace` is a read-only copy, and deliberately not updateable.** It is delivery only, never a working copy. Config edits made inside a consuming project's `.marketplace` are discarded.
- **Authoring happens in the Config Repo itself.** To change preferences, open a Sandbox on `claude-config`, which has a real remote and can push. This is the Dogfooding Deploy case.
- **The marketplace is named `claude-config`, not `local`.** Marketplace registration is per-user and unique by name: adding a second marketplace under an existing name replaces the first. Several projects each registering a `local` marketplace would silently clobber each other on the Host.
- **Registration goes in the target's `.claude/settings.local.json`, and the ignore in `.git/info/exclude`.** Both are untracked, so the script leaves no trace in a shared repository's history and never points a teammate at a `.marketplace` directory they do not have.
- **A fresh Host is not covered.** It still needs the Config Repo cloned once, which still needs the PAT once. Acceptable, because a human is present — but the README must say so.
