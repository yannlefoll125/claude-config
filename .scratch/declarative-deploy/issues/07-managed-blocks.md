# 07: Managed Blocks — drift detection and mechanical refresh

**What to build:** The marker format and its lifecycle. Suite-written prose inside a
Target's tracked markdown is wrapped in begin/end comment markers stamped with a content
hash; whole seeded files carry a hash header instead. Check mode compares stamps against
the installed Payload's content and reports drift — Apply never writes tracked files on a
normal run. An explicit refresh invocation rewrites marker contents only, leaving
everything outside the markers byte-identical. Deleting the markers forks the block out
of management: refresh and check both ignore it thereafter.

**Blocked by:** 03 (check mode, staleness hook, apply skill).

**Status:** ready-for-agent

- [ ] Marker format defined (block id + content hash) for inline blocks and whole seeded files
- [ ] Normal Apply run never modifies a tracked file, even when drift exists
- [ ] Check mode reports each drifted block with the refresh step that cures it
- [ ] Explicit refresh rewrites only marker contents; surrounding hand-written text is byte-identical
- [ ] A block with deleted markers is ignored by both check and refresh (fork honored)
- [ ] Hand-edits inside markers are overwritten by refresh, as documented
