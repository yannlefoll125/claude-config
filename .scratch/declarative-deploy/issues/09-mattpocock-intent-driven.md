# 09: install-mattpocock goes intent-driven

**What to build:** The mattpocock install skill stops carrying inline "standard answers"
and reads its options — tracker flavor, triage labels, overlays, target file for the
agent-skills block — from the Intent, which Setup wrote and chains into as today. Apply
handles the plugin install itself (per the plugins ticket); the skill keeps only the
LLM-necessary work: running the plugin's setup from its cache and placing the resulting
prose. Everything it writes into tracked markdown lands inside Managed Blocks (or
hash-headed seeded files), so from then on drift is check-visible and refresh mechanical.

**Blocked by:** 07 (Managed Blocks), 08 (Setup decide step).

**Status:** ready-for-agent

- [ ] The skill reads every option from the Intent; its inline standard answers are gone
- [ ] Interactive mode still works and records its outcomes back into the Intent
- [ ] All markdown it writes is marker-wrapped or hash-headed; a subsequent check run reports clean
- [ ] Plugin installation is delegated (the skill no longer runs the plugin CLI itself)
- [ ] Re-run updates blocks in place via the marker machinery, never duplicates
