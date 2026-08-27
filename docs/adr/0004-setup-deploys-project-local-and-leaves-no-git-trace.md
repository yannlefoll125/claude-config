---
status: accepted
---

# `/setup` deploys project-local, and leaves no trace in the Target's git

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
