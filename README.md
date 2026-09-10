# claude-config

One person's opinionated [Claude Code](https://claude.com/claude-code) configuration — skills, output styles, and scripts — plus the machinery that installs it into any project and keeps those copies current.

It is published read-only: fork it, gut it, replace the opinions with your own. The machinery is the reusable part; the preferences are just mine.

## Design philosophy

This is a personal-use config, and its scope is deliberately narrow rather than portable:

- **Claude Code only** — no attempt to serve other agents or editors.
- **Linux** — the scripts and tooling assume a Linux host; nothing is tested elsewhere.
- **Sandboxed by default** — designed around running Claude Code inside a libvirt VM: the sandbox holds no credentials, pushing happens only from the host, and setup enables auto permission mode only when it detects virtualisation.
- **Relative paths, never absolute** — a consequence of the sandbox assumption that matters if you fork this and work with an agent: the same repo is visible from the host and from the sandbox at *different* absolute paths, so everything persisted (symlinks, settings, references inside artifacts) is expressed relative to the repo or the target project. An agent that writes an absolute path into a committed file produces something that dangles in the other environment (see ADR 0009).

"Designed around" is not "limited to": every artifact must work identically from the host and from a sandbox (see `docs/adr/`), so nothing breaks if you run unsandboxed — you just lose the safety rationale behind some of the defaults.

## What's inside

The **payload** — the three directories an install copies into a project's `.claude/`:

- `skills/` — custom slash commands / agent skills:
  - `commit`, `commit-plan` — commits bundled into logical `<topic>: <message>` units; never pushes.
  - `setup-claude-config` — one-shot project setup: permission mode, model, notifications, statusline.
  - `self-handoff` — persist a session to `SELF_HANDOFF.md` before `/clear`, resume after.
  - `one-by-one` — walk open decision points one multiple-choice prompt at a time.
  - `install-mattpocock` — install and configure the `mattpocock-skills` plugin (from the official plugin marketplace) with standard answers.
- `output-styles/` — e.g. `eli5`.
- `scripts/` — a statusline script and opt-in git hooks.

Everything else is tooling (`claude-config-install`, `claude-config-push`, `Makefile`) or documentation (`CONTEXT.md`, `docs/adr/`) and never reaches a target project.

## Distribution model

Artifacts are **copied, never linked or loaded in place**. That is a deliberate trade: projects stay self-contained (a clone of your project has the skills with no external dependency), at the cost of copies going stale until the next install.

- **Install** — `claude-config-install [project]` copies the payload into the project's `.claude/`, writes a manifest (version stamp + file list), and records the project as a subscriber in `~/.config/claude-config/subscribers`. On re-install, only files the previous manifest listed are deleted — the project's *own* skills and scripts in the same directories are never touched.
- **Push** — `claude-config-push` re-runs the install into every subscriber. It writes into projects beyond the one being worked on, so by convention it is always a human step, never an agent's.
- **Setup** — `/setup-claude-config` in a Claude Code session applies the base settings (written to the project's gitignored `.claude/settings.local.json`). Safe to re-run.

### Dogfooding

The repo is a target of its own payload: skills are authored under `skills/` at the root, and the installed copies under `.claude/skills/` are what Claude Code actually loads while working *on this repo*. The two are synced in the same commit (agents here run `claude-config-install .` as part of committing), so work in progress never leaks into the live config, and every change is exercised here before it's pushed anywhere else.

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
> /setup-claude-config         # apply base settings
```

Later, after updating the clone: `claude-config-push` refreshes every project you've installed into.

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

This is a non-collaborative repo by design: it tracks one person's preferences, so pull requests won't be merged, and there is no support — if something doesn't work in your fork, the fix is yours to make.

Ideas are a different matter. If you've forked this and found a better shape for some part of it, or you see a flaw in the design, I'd like to hear about it — open an issue. Observations and ideas, not questions: an issue is welcome when reading it makes the design better, and "how do I…" issues will be closed without reply.

## License

[MIT](LICENSE) — fork and modify without limitation.
