# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` — never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## Sub-efforts

A big effort addressed incrementally (e.g. a large Jira story used as an umbrella) may hold **sub-efforts**: self-contained buildable chunks nested one level below it. Sub-efforts don't recurse, and plain feature directories are untouched — nesting is opt-in for umbrella efforts only.

- Layout: `.scratch/<effort>/<sub-effort>/` with its own `spec.md` and `issues/<NN>-<slug>.md`, following the same conventions as a feature directory.
- Each sub-effort is self-contained: ticket numbering, blocking edges, and the frontier are scoped to its own `issues/` directory. A blocking edge that crosses sub-efforts is a sign the split is wrong; merge or re-cut instead.
- The sub-effort's spec references the parent's material (decision log, story, map) by path rather than restating it.
- Spin a sub-effort only for a chunk whose decisions have cleared enough to spec and build; the parent effort keeps absorbing ad-hoc work and open questions directly.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed). When working a sub-effort, the sub-effort directory is the target.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` — the Notes / Decisions-so-far / Fog body.
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
