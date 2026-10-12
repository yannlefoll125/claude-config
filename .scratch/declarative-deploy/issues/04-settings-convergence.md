# 04: Settings convergence from Intent

**What to build:** Apply converges the base settings from the Intent's policies: model,
notifications, permission mode, statusline. Policies are evaluated at Apply time in
Apply's own environment; environment-dependent writes are monotone (a positive evaluation
writes, a negative one leaves any existing value untouched and reports). The statusline
key is written as a command string that resolves the Target's deployed script at render
time from the statusline's documented stdin JSON, so the persisted value is
environment-independent. Apply owns a fixed, known key set and never touches keys outside
it. Check mode reports drift for each owned key.

**Blocked by:** 03 (check mode, staleness hook, apply skill).

**Status:** ready-for-agent

- [ ] Each owned key converges from its Intent policy; a key absent from the Intent is removed only if Apply owns it
- [ ] Keys outside the known set survive convergence byte-for-byte
- [ ] Virtualisation gate evaluated at Apply time via the stubbed detector; both outcomes tested
- [ ] Monotone rule tested: a non-virtualised Apply run after a virtualised one preserves the auto permission mode
- [ ] Statusline command contains no absolute path and resolves the deployed script under mock stdin JSON carrying two different mount paths
- [ ] Second Apply run is a no-op (idempotency); check mode goes silent once converged
