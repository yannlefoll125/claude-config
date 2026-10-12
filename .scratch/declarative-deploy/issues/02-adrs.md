# 02: ADRs for the decided architecture

**What to build:** The decision record catches up with the grilling's outcomes. A new ADR
supersedes ADR-0005: a deterministic writer returns, split at decide (Setup, prompt-driven)
/ apply (deterministic script), explaining why this differs from the script-plus-report
option 0005 rejected and why prompt-driven correctness is retained for the decide step
only. ADR-0006 is amended: the virtualisation gate's evaluation moves to Apply time and
is monotone across environments (a negative evaluation never strips an existing value).
ADR-0004's consequence about the statusline command is amended: the pointer to the
deployed script resolves at render time from the statusline's documented stdin JSON, so
no absolute path is persisted.

**Blocked by:** None (can start immediately).

**Status:** ready-for-human

- [x] Superseding ADR exists, marks ADR-0005 superseded, and records the decide/apply trade-off with the considered alternatives from the decision log
- [x] ADR-0006 amended with Apply-time, monotone gate evaluation
- [x] ADR-0004 consequence amended with render-time statusline resolution
- [x] All three use the glossary vocabulary (Intent, Apply, Managed Block, Setup) and the repo's ADR format
