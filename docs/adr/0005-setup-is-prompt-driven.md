---
status: accepted
---

# `/setup` is a prompt-driven skill, not a deterministic script

`/setup` explores the Target, presents a recommended set of choices led by the recommended
answer, and writes only after confirmation. There is no install script and no
machine-readable report.

## Considered Options

- **A script that writes a report for the agent to resolve.** The script performs every
  unambiguous action, records what it could not decide in a markdown file, and the agent
  reads that file and asks the user. Attractive because the script stays the only writer,
  which keeps the whole thing deterministic and testable. Rejected because its main payoff
  is unattended operation, and a human is always present at Bootstrap. Pre-answering in
  the skill invocation argument gets the same effect with nothing to build.
- **Letting the agent decide everything freely** — rejected. Two Sandboxes would end up
  differently configured from the same Payload, which is the failure a config repo exists
  to prevent.

## Consequences

Correctness lives in precisely written prose rules rather than code, so the skill will
need iteration to get right. The rules must be specific enough to verify — "update the
block in place rather than appending a duplicate", not "handle existing files sensibly".

`/setup` belongs to this repo and knows what it deploys. There is no manifest and no
indirection. If a second preference set ever exists, copy the skill and adapt it; do not
build the generic version first.
