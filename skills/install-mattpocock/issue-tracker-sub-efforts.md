# Overlay: sub-efforts

Our extension to the plugin's `issue-tracker-local.md` seed template. After seeding `docs/agents/issue-tracker.md` from that template, apply both edits below to the seeded file.

## Insert as a new section, directly before the "publish to the issue tracker" section

````markdown
## Sub-efforts

A big effort addressed incrementally (e.g. a large Jira story used as an
umbrella) may hold **sub-efforts**: self-contained buildable chunks nested one
level below it. Sub-efforts don't recurse, and plain feature directories are
untouched — nesting is opt-in for umbrella efforts only.

- Layout: `.scratch/<effort>/<sub-effort>/` with its own `spec.md` and
  `issues/<NN>-<slug>.md`, following the same conventions as a feature
  directory.
- Each sub-effort is self-contained: ticket numbering, blocking edges, and the
  frontier are scoped to its own `issues/` directory. A blocking edge that
  crosses sub-efforts is a sign the split is wrong; merge or re-cut instead.
- The sub-effort's spec references the parent's material (decision log, story,
  map) by path rather than restating it.
- Spin a sub-effort only for a chunk whose decisions have cleared enough to
  spec and build; the parent effort keeps absorbing ad-hoc work and open
  questions directly.
````

## Append to the body of the "publish to the issue tracker" section

````markdown
When working a sub-effort, the sub-effort directory is the target.
````
