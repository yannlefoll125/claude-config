# 06: Plugins from Intent

**What to build:** The plugin set becomes part of the declared configuration, with
split-scope convergence: the project-scope settings entry is the shared, declarative
part; the plugin cache lives in each environment's home and is converged by whichever
environment's Apply runs (prompted there by the staleness hook). Apply installs
Intent-listed plugins at project scope through the plugin CLI when it is available, and
skips with a one-line reason when it is not. A plugin dropped from the Intent is
reported for manual removal — never uninstalled, since a hand-installed plugin is
indistinguishable from the suite's (stateless-removal decision).

**Blocked by:** 03 (check mode, staleness hook, apply skill).

**Status:** ready-for-human

- [x] Intent-listed plugin converges via the stubbed plugin CLI at project scope; already-installed is a reported no-op
- [x] CLI unavailable → skip with reason, nonzero-free exit, rest of Apply unaffected
- [x] Dropped plugin → report-only, nothing uninstalled, settings entry left for the user
- [x] Check mode reports an Intent-listed plugin missing from project scope
- [x] Split-scope behavior documented in the report wording (entry converged vs cache per-environment)
