# 13: Review follow-up — two doc decisions only the user can make

**What to decide:**

1. *"converge" vocabulary*: CONTEXT.md's Apply entry lists `converge` under `_Avoid_`,
   but the README, the apply-claude-config skill description, and Apply's own
   `drift target: run /apply-claude-config to converge` line all use it as the
   user-facing verb (the glossary definition itself opens with "Converging"). Either
   drop it from the `_Avoid_` list or rewrite the user-facing wording.
2. *Stale spec sentence*: `.scratch/declarative-deploy/spec.md` still says "Install
   invokes the Target's freshly copied Apply after the copy step" — superseded by the
   same spec's revised decision 3 (Apply runs in-session only; the implementation
   follows the revision). Amend or annotate the spec if it stays a reference document.

**Blocked by:** None.

**Status:** ready-for-human
