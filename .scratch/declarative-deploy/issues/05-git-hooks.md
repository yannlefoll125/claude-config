# 05: Git hooks from Intent

**What to build:** Hook enablement becomes declarative. Hooks listed in the Intent are
symlinked into the repository's hooks directory (relative links, per ADR-0009, so they
resolve from Host and Sandbox alike). A hook dropped from the Intent is removed only when
its symlink resolves into the Payload's hooks directory — the ownership heuristic; a
foreign hook occupying the slot is refused with a one-line explanation, never replaced or
deleted. The standalone per-hook enable script retires. Check mode reports hooks the
Intent wants but that aren't armed, and vice versa.

**Blocked by:** 03 (check mode, staleness hook, apply skill).

**Status:** ready-for-agent

- [ ] Intent-listed hooks are armed as relative symlinks; re-run changes nothing
- [ ] Dropping a hook from the Intent removes the suite's symlink
- [ ] A foreign hook (file or symlink elsewhere) is never modified; Apply refuses with an explanation
- [ ] The standalone enable script is gone from the Payload and its documented flow replaced by Intent + Apply
- [ ] Check mode detects both missing and surplus suite-owned hooks
