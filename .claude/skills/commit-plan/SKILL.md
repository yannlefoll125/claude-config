---
name: commit-plan
description: 'Dry-run of /commit — plan the logical commits (bundles, files, messages) for the current changes and show the plan without committing anything. Invoke when the user asks what would be committed, wants a commit plan, or wants to preview a commit.'
argument-hint: 'free-form instructions — omit to plan for all current changes'
---

Plan commits exactly as `/commit` would, then show the plan instead of committing.

Read `../commit/SKILL.md` (sibling of this skill's base directory) and follow it as if invoked, passing this skill's arguments through as if they were `/commit`'s — but stop before anything mutates: no staging, no `git config` writes, no commits. That skips its identity check and the commit execution; everything through bundle planning runs as written.

Report the plan: each bundle in commit order with its files and its `<topic>: <message>` line. Anything the doubt gate would have asked about goes into the report as open questions instead of an interactive ask. End by noting that `/commit` executes the plan.
