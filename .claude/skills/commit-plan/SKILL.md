---
name: commit-plan
description: 'Dry-run of /commit — plan the logical commits (bundles, files, messages) for the current changes and show the plan without committing anything. Invoke when the user asks what would be committed, wants a commit plan, or wants to preview a commit.'
argument-hint: 'free-form instructions — omit to plan for all current changes'
---

Plan commits exactly as `/commit` would, then show the plan instead of committing.

Read `../commit/SKILL.md` (sibling of this skill's base directory) and follow its "Project overrides", "Interpret the arguments", and "Plan the bundles" sections, passing this skill's arguments through as if they were `/commit`'s. Skip its "Check identity" and "Commit" sections — this run changes nothing: no staging, no `git config`, no commits.

Report the plan: each bundle in commit order with its files and its `<topic>: <message>` line. Anything the doubt gate would have asked about goes into the report as open questions instead of an interactive ask. End by noting that `/commit` executes the plan.
