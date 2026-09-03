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

Hold the points as an ordered working list. The list is mutable — see "Adapt" below. Keep each point's numbering or label exactly as the source list had it ("3.", "P-7", "point B") and present it under that identifier; number newly added points by extending the same scheme.

## The loop — one point per turn

For the current point:

1. Write the point, plus just enough explanation to decide: what it is, why it matters, the trade-off if there is one.
2. Ask with the AskUserQuestion tool, one single-select question:
   - **First option: your recommendation**, labeled "(Recommended)", per the tool's convention.
   - Optionally one or two other predefined answers.
   - The tool adds its own "Other" free-form option automatically; that covers both free-form answers and "let's discuss this". Add no free-form or chat option of your own.

## Advancing — the hard rule

- User picked a predefined answer → record it and present the next point immediately.
- User typed a free-form "Other" answer (a custom answer, a question, or "let's discuss") → the loop is suspended and you are in **chat mode** on this point. Discuss in plain prose, and end every chat-mode reply as prose — no AskUserQuestion, no options, no "ready to move on?". The user ends chat mode, never you: the loop resumes only on an explicit user signal — "next", "move on", "that's settled", or a concrete answer stated in the chat. Your own sense that the discussion is settled is not a signal; without one, the next turn is still chat. On the signal, record the decision and present the next point.

## Adapt

Answers change the landscape. After each recorded decision, reconsider the list:

- Add a new point an answer just surfaced.
- Reword or drop a future point an answer made moot.
- Return to an already-answered point when a new answer invalidates its recorded decision — say explicitly that you are reopening it and why.

## Finish

All points resolved → post a recap: each point with its recorded decision, one line each. Then carry out whatever work the decisions unblock, or state what happens next.
