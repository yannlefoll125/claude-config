---
status: accepted
---

# Artifacts and setup machinery are Host/Sandbox-agnostic

The same project directory is visible from two environments: the Host, and the Sandbox it
is mounted into — usually at a different absolute path. Anything an Artifact or a setup
script persists into a Target (links, paths in config, recorded state) therefore must not
encode which environment wrote it: everything persisted is expressed relative to something
both environments share, normally the project root, and scripts never branch on where they
are running.

The motivating incident: the git-hooks `enable` script symlinked `.git/hooks/commit-msg`
to an absolute path. Created on the Host, the link dangled in the Sandbox — and git skips
an unresolvable hook silently, so the Artifact simply stopped working with nothing to see.
The fix (a repo-relative link) is the pattern this ADR generalises.

## Considered Options

- **Set up per environment** — re-run the setup step on whichever side broke. Rejected:
  the failure is silent, so nobody knows to re-run it, and the two environments would
  fight over the same persisted file.
- **Detect the environment and rewrite paths** — rejected. Detection answers "which side
  am I on" only at write time; the other side still reads a path that is wrong there.

## Consequences

Persisted references are relative, so they survive the repo being mounted anywhere, but
scripts can no longer assume a canonicalised path computed once stays valid later.
Violations tend to be invisible (git skipping a dangling hook is the norm, not the
exception), so agnosticism is the default posture when authoring an Artifact, not a
property to retrofit after a bug report.
