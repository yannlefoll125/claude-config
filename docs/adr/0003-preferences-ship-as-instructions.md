---
status: accepted
---

# Preferences ship as instructions, not as auto memory

Standing preferences are authored as an instructions file in `dist/deploy/` and deployed
by `/setup` as `CLAUDE.local.md`. The Payload ships no auto memory files.

## Why

Auto memory is what Claude writes for *itself*, from corrections observed during work. The
agent can rewrite or delete a memory mid-session, so a shipped memory silently stops
matching the Config Repo and nobody notices. Instructions are authored by the user and
owned by the Config Repo.

Auto memory is also keyed per repository (`~/.claude/projects/<project>/memory/`), so
there is no single location a shipped set could seed. Reaching every project would mean
pointing `autoMemoryDirectory` at one shared folder, which collapses every project's
private notes into one pool.

## Consequences

`dist/memories/` does not exist, and `autoMemoryDirectory` is deliberately left alone.

Instructions load into context on every request, so the Payload's instructions file is a
permanent token cost. Keep it short. If it ever outgrows one file, `.claude/rules/` with
path-scoped frontmatter is the escape hatch — at the cost of landing inside the Target's
git, which [ADR-0004](./0004-setup-deploys-project-local-and-leaves-no-git-trace.md)
otherwise avoids.
