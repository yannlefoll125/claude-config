# Handoff — claude-config, design complete, ready to build

**Repo:** `/workspace` (public GitHub, remote is set — `git remote -v`)
**Session date:** 2026-08-08
**Next session's goal:** build it, with `/mattpocock-skills:implement`.

The user has deliberately skipped the spec and ticket passes. **The ADRs are the input.**
`/implement` expects "a spec or set of tickets" — point it at `docs/adr/0001`–`0008` and
`CONTEXT.md` instead. Do not write a spec first unless the user asks for one.

## Read these first

The design is fully written down. Do not re-derive it, and do not re-open it.

- `/workspace/CONTEXT.md` — glossary, 13 terms, rewritten this session
- `/workspace/docs/adr/0001` … `0008` — the live decisions, all `status: accepted`
- `/workspace/docs/adr/archive/` — six ADRs from a previous design. **Dead.** Read
  `archive/README.md` before touching anything in there. They describe a private repo, a
  vendored marketplace, a host git server, a PAT in the Sandbox, and shipped memories.
  None of that exists any more.

## State of the repo

Nothing has been built. `git status` shows only `?? .claude/`, `?? CONTEXT.md`, `?? docs/`.

Tracked files, in full:

- `output-styles/eli5.md`
- `scripts/statusline.sh`

Neither has moved to `dist/` yet. The `dist/` tree described throughout the ADRs does not
exist on disk.

Nothing is committed. Pushing is the user's step, from the Host — see ADR-0008.

## Decided, but not written into any ADR

These came up in conversation and the user did not object, but they are not durable yet.
Confirm them before specifying against them.

- **Plugin name and marketplace name are both `claude-config`.** I proposed this; the user
  neither confirmed nor rejected it. ADR-0001's example commands assume it.
- **`dist/` v1 contents:** the `/setup` skill, the SessionStart staleness hook,
  `output-styles/eli5.md`, `deploy/statusline.sh`, `deploy/CLAUDE.local.md`, and a settings
  fragment. Same status — proposed, unopposed, unconfirmed.

## Open questions the build will hit

These are the gaps between "decided" and "buildable". None of them needs a design session —
they are the details an ADR deliberately does not fix. Resolve each as you reach it, one
question at a time (see the working agreement below).

- **What actually goes in the deployed instructions file.** ADR-0003 says preferences ship
  as instructions; it does not say which. The two live candidates are the user's own
  standing preferences, currently held as auto memory in
  `/home/agent/.claude/projects/-workspace/memory/` (see below).
- **Version stamp format and location.** ADR-0007 says `/setup` writes one and the hook
  reads it. Neither shape is specified.
- **The hook's exact behaviour** — what it prints, whether it can block, what it does when
  no stamp exists (fresh project, never set up).
- **`/setup`'s exploration list and its question sections.** ADR-0005 fixes the *shape*
  (prompt-driven, recommended-answer-first, confirm before writing). It does not say what
  it explores or what genuinely branches. Matt Pocock's `setup-matt-pocock-skills` SKILL.md
  is the reference model the user explicitly endorsed — read it before designing this.
- **The GitHub Action.** ADR-0007 fixes the policy, not the workflow file.
- **Whether `scripts/statusline.sh` needs any change** when it becomes a Deployed Artifact.

## Working agreement — read this before asking anything

The user corrected me on process three times this session. All three are now in memory,
but they matter enough to repeat.

- **One question at a time, via `AskUserQuestion`.** Suggested answers plus a stated
  recommendation. Never a batch, never a numbered round — *this overrides the `grilling`
  skill's own instructions, which explicitly ask for whole-frontier rounds.*
- **A question stays open until they pick a suggestion or say "move on".** A free-form
  answer does not close it. Neither does a discussion.
- **Summarising and advancing is the same violation as re-prompting.** Posting a "settled
  so far" list and then asking the next question got called out directly. After they make
  a point in discussion, respond to the point and stop. If unsure whether a topic is
  closed, ask "anything else on this?".
- **When they give a reason for a decision, that decision is closed.** They were visibly
  annoyed by project-local config being re-argued after they had explained why twice.
  Do not counter a stated preference with a cleverer framing.

They discuss well and push back usefully — the best decisions this session came from their
objections, not from my options. But the pacing is theirs.

## Environment facts worth not re-discovering

- Sandbox is Fedora 44 on KVM. `systemd 259`. `systemd-detect-virt` → `kvm`.
  `/sys/class/dmi/id/sys_vendor` → `QEMU`. Podman *is* a known `systemd-detect-virt` ID.
- `/workspace` is a virtiofs mount from the Host, so it survives VM shutdown. `$HOME`
  inside the Sandbox is on a real disk and also persists.
- **No credential of any kind in the Sandbox.** No `gh`, no SSH key, no gitconfig, no
  credential helper. `git ls-remote origin` fails. This is by design — ADR-0008.
- No working secret manager: `secret-tool` is installed but there is no keyring daemon.
- The Sandbox has internet. Public git reads work.
- `grill-with-docs` and `setup-matt-pocock-skills` are `disable-model-invocation: true` —
  the model cannot launch them, only the user can type them.

## Memory files touched this session

Three edits under `/home/agent/.claude/projects/-workspace/memory/`, all process, no
design:

- `one-question-at-a-time.md` — added that it overrides skill instructions, and that
  summarise-and-advance counts as advancing
- `prefer-project-local-claude-config.md` — added that it is settled and must not be
  re-argued

Note the tension worth knowing about: those memories are the user's *own* standing
preferences, and ADR-0003 says preferences should ship as instructions rather than auto
memory. The Collection has not yet absorbed them.

## Suggested skills

- **`/mattpocock-skills:implement`** — the point of the next session. It is
  `disable-model-invocation: true`, so the user must type it; the model cannot launch it.
  Same for `grill-with-docs` and `setup-matt-pocock-skills`.
- **`/mattpocock-skills:writing-for-agents`** — the most important one here, because the
  main deliverable *is* a skill. ADR-0005 makes `/setup`'s correctness depend on precisely
  written prose rather than code, so the quality of the prose is the quality of the
  product. Invoke it before writing `SKILL.md`, not after.
- **`/mattpocock-skills:domain-modeling`** — only if building turns up a term the glossary
  is missing or gets wrong. `CONTEXT.md` is a glossary and nothing else; keep
  implementation detail out of it.

Deliberately **not** suggested: `to-spec` and `to-tickets` — see below.

## Recommended route: straight to `/implement`, four times

This was checked against Matt's own skill map via `/ask-matt`. His flow branches on one
question: *is this a multi-session build?* Yes means `/to-spec` → `/to-tickets` →
`/implement` per ticket. No means `/implement` directly.

**The recommendation is to skip the spec and ticket passes.** Three reasons:

- **The ADRs already carry more than a spec would.** Eight of them, with Considered Options
  and Consequences. A spec would largely restate them — and a spec that drifts from the
  ADRs is precisely the failure the 2026-08-08 session existed to clean up. It would be a
  ninth document able to disagree with the other eight.
- **The work is already broken up**, with clean boundaries, by the build order below. That
  is a ticket list without the ticket files.
- **The ratio is off.** The repo has two tracked files and already carries a glossary,
  eight ADRs, an archive and this handoff. A spec and a ticket set would be more process
  than product.

**The caveat, stated honestly.** Matt's context-hygiene rule keeps grilling, spec and
tickets in one unbroken window — and this one is broken, because the user shut the VM
down. That is normally the argument *for* `/to-spec`. It does not bite here only because
the ADRs are the paper trail that rule exists to protect.

**What should change this decision:** if the `/setup` skill turns out substantially bigger
than it looks. ADR-0005 says outright that it will need iteration. If step 2 below starts
sprawling across sessions, stop and reconsider `/to-spec` — but discover that by starting
it, not by specifying it up front.

### Build order

Run `/implement` once per step, in a **fresh context window each time**. The build order
itself was not agreed with the user — treat it as a proposal.

1. **Plugin skeleton.** Move `output-styles/eli5.md` and `scripts/statusline.sh` into
   `dist/`; add `dist/.claude-plugin/plugin.json` and root `.claude-plugin/marketplace.json`.
   The smallest installable thing, and it proves ADR-0001 and ADR-0002 before any skill
   exists. Start here.
2. **The `/setup` skill** (ADR-0004, 0005, 0006). Largest and least certain piece. Load
   `/writing-for-agents` before writing `SKILL.md`.
3. **Version stamp + SessionStart hook** (ADR-0007). Needs `/setup` to exist first.
4. **The GitHub Action** (ADR-0007). Last, because it is the only part that cannot be
   tested locally.

Test with `claude --plugin-dir dist` throughout; use commit + push + `/plugin update` only
to check real delivery. Both paths and their failure modes are in ADR-0008.
