# 01: Apply walking skeleton and CLI-seam test harness

**What to build:** An Apply script shipped as a Payload Artifact. Run inside a Target
without an Intent, it changes nothing and prints a one-line pointer to Setup; its exit
codes distinguish "nothing to do" from failure. Alongside it, the repo's first automated
tests: a harness that creates a throwaway git repository as a Target, installs the
Payload into it, runs Apply through its real CLI, and asserts only external behavior
(exit code, report lines, resulting filesystem), with external commands stubbed via a
fake-bin directory prepended to PATH. A Makefile target runs the suite.

**Blocked by:** None (can start immediately).

**Status:** ready-for-human

- [x] Apply ships in the Payload and is runnable from a Target in both Host and Sandbox (relative resolution per ADR-0009, no absolute paths persisted anywhere)
- [x] In a Target with no Intent, Apply exits cleanly, changes nothing on disk, and reports a one-line pointer to Setup
- [x] Report convention established: one line per action — done / skipped-with-reason / drift-found
- [x] Test harness drives the real executable against a temp-git-repo Target; no test reaches into script internals
- [x] PATH fake-bin stubbing works and is demonstrated by at least one stubbed external
- [x] A Makefile target runs the whole suite; it passes
