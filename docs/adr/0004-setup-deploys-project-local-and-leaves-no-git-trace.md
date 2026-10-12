---
status: accepted — amended by ADR-0010
---

# `/setup` deploys project-local, and leaves no trace in the Target's git

> **Amended by [ADR-0010](./0010-setup-decides-and-a-deterministic-apply-writes.md)** — see [Amendment](#amendment-tracked-intent-and-render-time-statusline) below. The `statusLine.command` consequence is replaced, and the no-git-trace stance gains one exception.

Deployed Artifacts go into the project, never into the user's home directory:
`CLAUDE.local.md` at the project root, settings keys in `.claude/settings.local.json`,
scripts in `.claude/scripts/`. Every path `/setup` writes is added to the Target's
`.git/info/exclude`.

## Why project-local

The user works from the Host, and the project directory is mounted there. Project files
are therefore readable and editable from the Host; the Sandbox's home directory is not.
Their use is one project per Sandbox, so user-level scope would buy nothing and cost that
access.

## Why no git trace

`/setup` may run in a repository that is not the user's. `CLAUDE.local.md` is designed to
be gitignored, `settings.local.json` is untracked by convention, and `.git/info/exclude`
is per-clone and never committed — so not even the ignore rule leaves a mark.

## Consequences

Preferences are re-deployed per project. That is the accepted price of host visibility.

`statusLine.command` must point at the deployed copy under `.claude/scripts/`. It must
never point at the Config Repo, which is not mounted in a consuming Sandbox, nor into the
plugin cache, whose path is version-pinned and re-cloned on update.

## Amendment: tracked Intent and render-time statusline

The no-git-trace stance is unchanged, with one exception at the user's discretion: the
Target's Intent may be tracked per project, so the author's own repos can self-describe.
Setup adds the Intent to `.git/info/exclude` only when it is not already tracked, and the
machinery assumes neither state.

`statusLine.command` no longer persists any path to the deployed script. Apply writes a
command that reads `workspace.project_dir` from the statusline's documented stdin JSON and
invokes the script under `.claude/scripts/` relative to it. The statusline's working
directory and hook-style environment variables are undocumented for this setting, so
stdin is the only documented source valid on the Host and in a Sandbox alike
([ADR-0009](./0009-artifacts-are-host-sandbox-agnostic.md)). The rule that it never points
at the Config Repo or the plugin cache stands.
