# claude-config

One person's opinionated [Claude Code](https://claude.com/claude-code) configuration — skills, output styles, and scripts — plus the machinery that installs it into any project and keeps those copies current.

It is published read-only: fork it, gut it, replace the opinions with your own. The machinery is the reusable part; the preferences are just mine.

## Design philosophy

This is a personal-use config, and its scope is deliberately narrow rather than portable:

- **Claude Code only** — no attempt to serve other agents or editors.
- **Linux** — the scripts and tooling assume a Linux host; nothing is tested elsewhere.
- **Sandboxed by default** — designed around running Claude Code inside a libvirt VM: the sandbox holds no credentials, pushing happens only from the host, and the standard permission policy turns on auto mode only where Apply detects virtualisation.
- **Relative paths, never absolute** — a consequence of the sandbox assumption that matters if you fork this and work with an agent: the same repo is visible from the host and from the sandbox at *different* absolute paths, so everything persisted (symlinks, settings, references inside artifacts) is expressed relative to the repo or the target project. An agent that writes an absolute path into a committed file produces something that dangles in the other environment (see ADR 0009).

"Designed around" is not "limited to": every artifact must work identically from the host and from a sandbox (see `docs/adr/`), so nothing breaks if you run unsandboxed — you just lose the safety rationale behind some of the defaults.

## What's inside

The **payload** — the three directories an install copies into a project's `.claude/`:

- `skills/` — custom slash commands / agent skills:
  - `commit`, `commit-plan` — commits bundled into logical `<topic>: <message>` units; never pushes.
  - `setup-claude-config` — decide a project's configuration (permission mode, model, notifications, statusline, git hooks, plugins) and record it as the Intent; safe to re-run.
  - `apply-claude-config` — converge the project to its Intent, check it read-only, or refresh drifted Managed Blocks.
  - `self-handoff` — persist a session to `SELF_HANDOFF.md` before `/clear`, resume after.
  - `one-by-one` — walk open decision points one multiple-choice prompt at a time.
  - `install-mattpocock` — configure the `mattpocock-skills` plugin (which Apply installs from the official plugin marketplace) from its answers in the Intent.
- `output-styles/` — e.g. `eli5`.
- `scripts/` — Apply (the script that converges a project to its Intent), the shipped Managed Block contents, a statusline script, and opt-in git hooks.

Everything else is tooling (`claude-config-install`, `claude-config-push`, `Makefile`) or documentation (`CONTEXT.md`, `docs/adr/`) and never reaches a target project.

## Distribution model

Artifacts are **copied, never linked or loaded in place**. That is a deliberate trade: projects stay self-contained (a clone of your project has the skills with no external dependency), at the cost of copies going stale until the next install.

- **Install** — `claude-config-install [project]` copies the payload into the project's `.claude/`, writes a manifest (version stamp + file list), and records the project as a subscriber in `~/.config/claude-config/subscribers`. On re-install, only files the previous manifest listed are deleted — the project's *own* skills and scripts in the same directories are never touched.
- **Push** — `claude-config-push` re-runs the install into every subscriber. It writes into projects beyond the one being worked on, so by convention it is always a human step, never an agent's.

Install and Push are pure file copies: neither touches a project's settings. What a project turns on is declared separately, in its **Intent**:

- **Intent** — `.claude/claude-config.json` records the project's choices as policies (e.g. "auto permission mode if virtualised", never "auto here"), so the same file holds on the host and in a sandbox. Hand-editable; track it in git or keep it excluded — the machinery works either way.
- **Setup** — `/setup-claude-config` in a Claude Code session is the decide step: it explores the project, proposes the standard answers, writes the Intent, and runs Apply. Safe to re-run; arguments amend the Intent ("keep notifications", "arm commit-msg", …).
- **Apply** — `.claude/scripts/apply`, run in-session through `/apply-claude-config`, converges the project to its Intent: settings keys in the gitignored `.claude/settings.local.json`, git hook symlinks, plugin installs. It only ever writes untracked state, and it evaluates policies in the environment whose session consumes them. To change a project's configuration, edit its Intent (or re-run Setup with overrides) and run `/apply-claude-config`.
- **Staleness check** — the Intent turns on a SessionStart hook that runs `apply --check` read-only. It stays silent while the project matches its Intent and installed payload; after a push, or a hand-edit, it reports the drift at the start of the next session and names the cure, usually `/apply-claude-config`.
- **Managed Blocks** — prose the suite writes into a project's tracked markdown (e.g. a section of `CLAUDE.md`) sits between `claude-config:begin`/`end` markers with a content hash. Apply only reports a drifted block; `/apply-claude-config refresh` rewrites it between the markers, never a byte outside. Delete the markers to keep a block as your own.

### Migrating an existing subscriber

A project installed before the Intent existed has settings but no record of why. Apply leaves such a project untouched and points at Setup, so each existing subscriber needs one `/setup-claude-config` conversation after its next install: Setup decides the Intent from the standard answers and the conversation, never by reading back the settings already there.

### Dogfooding

The repo is a target of its own payload: skills are authored under `skills/` at the root, and the installed copies under `.claude/skills/` are what Claude Code actually loads while working *on this repo*. The two are synced in the same commit (agents here run `claude-config-install .` as part of committing), so work in progress never leaks into the live config, and every change is exercised here before it's pushed anywhere else. The repo also carries its own tracked Intent (`.claude/claude-config.json`), so it is the first project configured the declarative way.

## Getting started

```bash
git clone https://github.com/yannlefoll125/claude-config.git   # or your fork
cd claude-config
make install    # symlinks claude-config-install / claude-config-push into ~/.local/bin
```

The symlinks resolve back to the clone, so the scripts always run from your checked-out version — don't replace them with plain copies.

Then, in any project:

```bash
claude-config-install          # copy the payload into ./.claude/
claude                         # start a session there
> /setup-claude-config         # decide the Intent; Apply converges it
```

Later, after updating the clone: `claude-config-push` refreshes the payload in every project you've installed into; where that leaves a project behind its Intent, the next session's staleness check says so and names the cure (`/apply-claude-config`, or its `refresh` for Managed Blocks).

## Forking and making it yours

1. Fork, clone, `make install`.
2. Delete the skills you don't want from `skills/` (and their copies in `.claude/skills/`); drop `install-mattpocock` if you don't use that plugin.
3. Adjust the defaults in `skills/setup-claude-config/` — model choice, permission mode, notifications are all opinions encoded there.
4. Rewrite `.claude/CLAUDE.md` and `CONTEXT.md` for your own conventions.

Nothing phones home and there is no registry: the subscriber list, manifest, and settings are all plain local files you can read in a few minutes.

## Design notes

- `CONTEXT.md` — the domain vocabulary (payload, target, manifest, subscriber, …) used consistently across docs and skills.
- `docs/adr/` — architecture decision records, including why artifacts ship as copied instructions, why the sandbox holds no credentials, and a prospective future shape where the payload becomes a Claude Code plugin.

## Feedback

This is a non-collaborative repo by design: it tracks one person's preferences, so there are no pull requests and no support — in your fork, you're the maintainer, and everything here is yours to use without owing anything back.

Issues stay open for one thing: the design itself. If you spot a flaw, or your fork found a better shape for some part, an issue is a way to send that upstream — whatever it improves lands back here in public, where every fork (yours included) can pull from it. "How do I…" questions don't have that effect, so they'll be closed without reply.

## License

[MIT](LICENSE) — fork and modify without limitation.
