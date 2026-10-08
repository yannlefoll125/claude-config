# Overlay: main-flow handback guard

Our addition to the `## Agent skills` block that the plugin's setup skill
writes into the project's CLAUDE.md (or AGENTS.md). The plugin's main-flow
skills (`/to-spec`, `/to-tickets`, …) are user-invoked only, and the
`/grilling` exit clause ("do not act until the user confirms") reads any
confirmation as a green light — so nothing in the plugin stops a session from
improvising a spec and tickets freehand once a grilling converges. This guard
closes that gap by handing the trigger back to the user.

After the setup skill has written or updated the `## Agent skills` block,
append the subsection below to that block. Idempotent: if a
`### Main-flow handback` heading already exists in the block, replace its body
instead of appending a duplicate.

````markdown
### Main-flow handback

Specs and ticket breakdowns are produced only by the user invoking `/to-spec`
and `/to-tickets` — never ad-hoc. When a grilling or any discussion converges
on a buildable idea, end the turn and name the next command. Even on
"go ahead", don't improvise the artifact: ask the user to invoke the slash
command instead. An ad-hoc spec or ticket set is a failure, not initiative.
````
