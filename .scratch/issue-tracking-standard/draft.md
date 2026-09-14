# Sequence-backed reference IDs — standalone draft for claude-config

> Hand-off document. Written 2026-09-11 in the dotfiles repo (its local
> effort tracker is the first intended consumer); self-contained so it
> can be dropped into claude-config and developed there. Nothing has
> been implemented anywhere yet.

## Problem

Tracked entities (efforts, tickets, notes — anything living as a
directory or file per item) are addressed by slug today. Slugs are
mutable and collide across time: a deleted effort's name can be reused,
and renaming one silently breaks every citation of it. Wanted: a
permanent, human-short reference per entity that survives renames and
deletions, sortable as a plain string.

## The model

- **Reference**: `REF = <PREFIX><SEQ>` — e.g. `E0042`. `<PREFIX>` is a
  single letter naming the entity class (`E` = effort). `<SEQ>` is an
  integer from a monotonic counter, zero-padded to a fixed width
  (4 digits) so lexicographic sort equals allocation order.
- **Naming**: the entity's directory (or file) is `<REF>-<slug>`
  (`E0042-hypr-config-test-suite/`). The slug stays for humans; the
  ref is the stable part.
- **State**: the counter lives in its own committed file (e.g.
  `.next-seq` beside the entity dirs), independent of the entities.
  Deleting an entity therefore never frees its number.
- **Allocation is script-backed**: numbers are only ever handed out by
  a script (working name `next-seq`); neither humans nor agents
  compute one by eyeballing the directory listing.

## Script contract (to be refined here)

`next-seq` — allocate and print the next reference.

1. Read the state file; scan the entity dirs for the max SEQ embedded
   in `<PREFIX>####-*` names.
2. `effective_last = max(state, max_scanned)` — this is the
   self-correction rule: a missing, corrupt, or stale state file is
   recovered from the surviving directory names, and a state file that
   is *ahead* of the directories (entities were deleted) wins, which is
   exactly what guarantees no reuse.
3. Allocate `effective_last + 1`, write it back to the state file,
   print the formatted ref.

Known limit, worth stating in its docs: if the state file is lost *and*
the highest-numbered entities were deleted, reuse becomes possible.
With the state file committed to git this is a non-risk in practice.

Micro-decisions for the script:

- State file semantics: last-allocated vs next-to-allocate. Suggest
  **last-allocated** — it compares directly against the scan max in
  step 2. (The name `.next-seq` then slightly lies; rename or accept.)
- Overflow past the pad width (`E10000`): sort order breaks. Either
  widen everywhere on the day it happens, or treat 9999 as a hard cap
  and fail loudly. At effort-creation rates this is theoretical;
  failing loudly is enough.
- Concurrency: single-user repos, so a lock is likely overkill; a
  `noclobber`-style write-if-unchanged check is cheap if wanted.

## The generalization question (the actual claude-config work)

The dotfiles instance is one hardcoded consumer: prefix `E`, width 4,
state `.scratch/.next-seq`, scan `.scratch/E????-*`. For ubiquitous
adoption, decide how the mechanism is parameterized and distributed:

1. **Where the script lives** — shipped by claude-config into each
   consumer (mirrored like skills), one binary on PATH, or vendored
   per repo and allowed to drift?
2. **How a consumer is declared** — CLI args
   (`next-seq --state <file> --prefix E --scan <glob>`), a per-tracker
   config block, or one convention-over-configuration layout every
   consumer must follow?
3. **One counter or many** — per entity class per repo (the model
   above), or ever global across repos? (Global sounds attractive and
   is probably a trap: it couples repo histories.)
4. **Prefix registry** — if more classes appear (`T` tickets, `N`
   notes…), where the letter→class mapping is recorded so two classes
   never share a letter within a scope.
5. **Agent-facing contract** — the line that goes into a tracker's
   conventions doc, e.g.: "creating an entity = call `next-seq`, name
   the dir `<REF>-<slug>`, never mint a ref by hand". Skills/CLAUDE.md
   integration is claude-config's home turf.

## Retrofit procedure (generic, per consumer)

1. Sort existing entity dirs by mtime ascending (approximation of
   creation order — accepted).
2. Assign refs incrementally from `<PREFIX>0001`, rename each dir to
   `<REF>-<slug>`.
3. Sweep the repo for path references to the old names (docs, specs,
   cross-links) and update them.
4. Seed the state file with the last assigned SEQ.
5. Record the convention in the tracker's conventions doc.
