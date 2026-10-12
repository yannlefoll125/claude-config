# 11: Review follow-up — two test coverage gaps

**What to build:** The claude-fable-5 spec review (2026-10-12) found two Testing-Decisions
scenarios only half-covered at the CLI seam:

1. *Tracked Intent*: no automated test runs Apply against a **tracked**
   `.claude/claude-config.json`; every test leaves it untracked. The tracked branch is
   exercised only by the ticket-08/10 manual demos. Low risk (Apply never branches on
   tracked-ness), but the spec names "tracked versus excluded Intent both work" as a
   scenario to cover.
2. *Virtualisation fallback chain*: `virtualised()` in `scripts/apply` is tested only
   through the `systemd-detect-virt` stub; the containerenv/dockerenv/`$container`/DMI
   fallback path (taken when the binary is absent) has no test. Needs a PATH without the
   real binary, so the fake-bin trick alone doesn't cut it.

**Blocked by:** None.

**Status:** needs-triage

- [ ] A test converges and checks a Target whose Intent is git-tracked
- [ ] Both fallback-path outcomes (virtualised and not) are exercised with the detector binary absent
- [ ] `make test` stays green
