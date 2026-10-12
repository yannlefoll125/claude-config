# 03: In-session entry points — check mode, staleness hook, apply skill

**What to build:** The machinery that makes drift visible and convergence a one-step
in-session action. Apply gains a read-only check mode: it compares the Target against its
Intent and the Manifest stamp against the installed Payload, changes nothing on disk,
exits distinctly for drift / clean / no-Intent, and prints one line naming the skill to
run. A thin skill runs Apply in the session's own environment (Host or Sandbox alike) and
relays its report. A SessionStart hook — itself one of the settings keys Apply converges
from the Intent, on by default, wired through the hooks-documented project-dir variable —
runs the check at session start so a stale Target greets the user with the suggestion.

**Blocked by:** 01 (Apply walking skeleton and CLI-seam test harness).

**Status:** ready-for-agent

- [ ] Check mode is read-only (byte-identical Target before and after) and its exit codes distinguish drift / clean / no-Intent
- [ ] Manifest-stamp staleness (installed Payload older than what the stamp records) is detected from day one
- [ ] The skill runs Apply in the current environment and relays the one-line-per-action report verbatim
- [ ] Apply converges the SessionStart hook entry from the Intent like any other owned settings key; disabling it in the Intent removes it
- [ ] Demoable: opening a session in a drifted Target surfaces the one-line suggestion; a clean Target stays silent
- [ ] All behavior covered through the CLI-seam harness
