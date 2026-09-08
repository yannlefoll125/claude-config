---
name: one-by-one
description: Walk the user through open points one at a time with a multiple-choice prompt per point, instead of dumping the whole list. Use whenever a review, grilling, or analysis leaves several points that each need a user decision. With arguments, answer that prompt first, then run its points one by one.
argument-hint: "optional prompt to answer first — omit to use the points already in context"
---

A review, grilling, or analysis often ends in a list of points that each need the user's input. A dumped list is impractical to work through. This skill replaces the dump: present each point alone, collect the decision, then move on.

## Gather the points

- No arguments: collect the open points from the current context — everything already raised that still needs a user decision.
- Arguments given: treat them as a prompt. Do that work first; its resulting points become the list.

Hold the points as an ordered working list. The list is mutable — see "Adapt" below. Keep each point's numbering or label exactly as the source list had it ("3.", "P-7", "point B"); number newly added points by extending the same scheme.

## The loop — one point per turn

For the current point:

1. Open with the progress marker: `**3/~7**` — points answered-so-far+this-one / estimated total. Every turn that asks the question carries the marker: the first presentation, a re-ask after "Explain", and the resume after chat mode. The total is an estimate, not a promise: the list is mutable (see "Adapt"), so recount it each time and let it drift as points are added or dropped.
2. Write the point under its source identifier ("3.", "P-7"), plus just enough explanation to decide: what it is, why it matters, the trade-off if there is one.
3. Ask with the AskUserQuestion tool, one single-select question:
   - **The question text carries the decision**: it starts with the marker ("3/~7 — …") and compactly restates what is being decided; the option descriptions carry the trade-offs. The UI collapses prose that precedes a tool call into a one-line summary, so nothing the user needs in order to decide may live only in step 2's write-up. Keep the short `header` for the topic.
   - **First option: your recommendation**, labeled "(Recommended)", per the tool's convention.
   - Optionally one or two other predefined answers.
   - **Last option: "Explain"** — always present, description like "explain this point in more depth first".
   - The tool adds its own "Other" free-form option automatically; that covers both free-form answers and "let's discuss this". Add no free-form or chat option of your own.

## Advancing — the hard rule

- User picked a predefined answer → record it, reconsider the list (see "Adapt"), and present the next point immediately.
- User picked "Explain" → not a decision. Re-ask the same question with the same options, embedding the fuller explanation in the question text after the marker. Ground it in the subject matter: quote the actual lines, code, or facts under discussion, and show a proposed change as concrete before/after text — abstractions only where the concrete material doesn't speak for itself. The question text is the only surface that renders in full here (prose in the same turn collapses per the rule above), so the whole explanation goes there. The loop stays active; this is not chat mode.
- User typed a free-form "Other" answer (a custom answer, a question, or "let's discuss") → the loop is suspended and you are in **chat mode** on this point. Discuss in plain prose, and end every chat-mode reply as prose — no AskUserQuestion, no options, no "ready to move on?". The user ends chat mode, never you: the loop resumes only on an explicit user signal — "next", "move on", "that's settled", or a concrete answer stated in the chat. Your own sense that the discussion is settled is not a signal; without one, the next turn is still chat. On the signal, record the decision and present the next point.

## Adapt

Answers change the landscape. After each recorded decision, reconsider the list:

- Add a new point an answer just surfaced.
- Reword or drop a future point an answer made moot.
- Return to an already-answered point when a new answer invalidates its recorded decision — say explicitly that you are reopening it and why.

## Finish

All points resolved → post a recap: each point with its recorded decision, one line each. Then carry out whatever work the decisions unblock, or state what happens next.
