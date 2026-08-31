---
name: one-by-one
description: Walk the user through open points one at a time with a multiple-choice prompt per point, instead of dumping the whole list. With arguments, answer that prompt first, then run its points one by one.
argument-hint: "optional prompt to answer first — omit to use the points already in context"
disable-model-invocation: true
---

A review, grilling, or analysis often ends in a list of points that each need the user's input. A dumped list is impractical to work through. This skill replaces the dump: present each point alone, collect the decision, then move on.

## Gather the points

- No arguments: collect the open points from the current context — everything already raised that still needs a user decision.
- Arguments given: treat them as a prompt. Do that work first; its resulting points become the list.

Hold the points as an ordered working list. The list is mutable — see "Adapt" below.

## The loop — one point per turn

For the current point:

1. Write the point, plus just enough explanation to decide: what it is, why it matters, the trade-off if there is one.
2. Ask with the AskUserQuestion tool, one single-select question:
   - **First option: your recommendation**, labeled "(Recommended)", per the tool's convention.
   - Optionally one or two other predefined answers.
   - **Last option: "Chat about this"** — the user wants to discuss before deciding.
   - The tool adds its own "Other" free-form option automatically; that is the free-form answer path. Add no free-form option of your own.

## Advancing — the hard rule

- User picked a predefined answer → record it and present the next point immediately.
- User picked "Chat about this" or typed a free-form "Other" answer → **stay on this point.** Respond, discuss, refine. Move to the next point ONLY when the user explicitly says so ("next", "move on", "that's settled") or picks a concrete answer. When the discussion feels settled, offer to advance (an AskUserQuestion with "Record X and go to next point (Recommended)" works well) — but the user makes that call, never you.

## Adapt

Answers change the landscape. After each recorded decision, reconsider the list:

- Add a new point an answer just surfaced.
- Reword or drop a future point an answer made moot.
- Return to an already-answered point when a new answer invalidates its recorded decision — say explicitly that you are reopening it and why.

## Finish

All points resolved → post a recap: each point with its recorded decision, one line each. Then carry out whatever work the decisions unblock, or state what happens next.
