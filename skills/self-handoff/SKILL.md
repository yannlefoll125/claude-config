---
name: self-handoff
description: Persist the session to SELF_HANDOFF.md before a /clear, and resume from it after. Derived from Matt Pocock's /handoff.
argument-hint: "handoff instructions — or how to continue"
disable-model-invocation: true
---

The user prefers a handoff file over /compact: write the session to `SELF_HANDOFF.md` at the repo root, let them /clear, then invoke this skill again to pick the work back up.

## Pick the mode

Judge from context which mode was meant, and announce it in your first line ("Writing handoff to `SELF_HANDOFF.md`…" / "Continuing from `SELF_HANDOFF.md` (dated …)"):

- A conversation with real work in it → **create**.
- A fresh context plus an existing `SELF_HANDOFF.md` → **continue**; wording like "continue", "resume", "pick up" also means continue.
- Any other arguments are instructions for the chosen mode: tailoring for create, steering for continue.
- Genuinely ambiguous → ask.
- Fresh context and no `SELF_HANDOFF.md`: nothing to summarize and nothing to continue — say so and stop.

## Create

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to `SELF_HANDOFF.md` at the repo root, overwriting any previous handoff.

- Open the header with the date and the current session id (lift it from the scratchpad path).
- Include a "suggested skills" section naming which skills the next agent should call the Skill tool for.
- Reference content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs) by path or URL instead of restating it.
- Redact secrets and PII: reference where a credential lives instead of inlining it.
- If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

In a git repo, keep the file out of version control locally: if `git check-ignore -q SELF_HANDOFF.md` fails, append `SELF_HANDOFF.md` to `.git/info/exclude`. `.gitignore` belongs to the user — leave it untouched.

## Continue

Read `SELF_HANDOFF.md` and orient before working:

1. Give a 2–3 line orientation: where the work stands and what you will do first.
2. Sanity-check freshness — compare the handoff's date and referenced commits against `git log`. Flag discrepancies in the orientation and proceed anyway: flag, never block.
3. Follow the handoff, honoring any first action it names (which may be to ask the user something) and any steering instructions passed with the invocation.

Leave the file in place; the next create overwrites it.
