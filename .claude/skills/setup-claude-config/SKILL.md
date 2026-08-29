---
name: setup-claude-config
description: Companion to install.sh — apply the base configuration to the current project, hands-off. Auto permission mode (when virtualised), notifications off, Fable model when available, statusline wired to the deployed script, then the standard install-mattpocock run. Safe to re-run; arguments tweak the setup ad hoc.
argument-hint: "ad hoc overrides — e.g. 'keep notifications', 'skip mattpocock', 'model sonnet', 'auto mode anyway'"
disable-model-invocation: true
---

Apply the base configuration to the current project, end to end, without stopping. `install.sh` copied the files (this skill arrived through it); this skill wires them up. Report each step's outcome in one line — no questions, no waiting on the user.

## Arguments

- No arguments → the full standard setup below.
- Anything else → ad hoc overrides: apply each instruction to the step it matches (e.g. "keep notifications", "skip mattpocock", "model opus", "auto mode anyway" on bare metal) and keep the defaults for every step not mentioned. Overrides meant for the mattpocock setup pass through to step 5.

## Ground rules

- Every settings write goes to the project's `.claude/settings.local.json`. Create it if missing; otherwise JSON-merge: set only the keys named below, leave every other key in the file untouched, never duplicate a key. This is what makes the skill safe to re-run.
- A step that cannot proceed (missing file, unavailable model) is skipped with a one-line explanation — it never aborts the rest.

## Step 1 — auto permission mode, gated by virtualisation

Detect virtualisation, in order, stopping at the first hit: `systemd-detect-virt` exits 0 with anything other than `none`; `/run/.containerenv` exists; `/.dockerenv` exists; `$container` is non-empty; `/sys/class/dmi/id/sys_vendor` names a hypervisor (QEMU, KVM, VMware, VirtualBox, Xen, Microsoft, Parallels, Bochs). The question is only "virtualised, yes or no" — never branch on which backend.

- Virtualised → set `permissions.defaultMode: "auto"`.
- Not virtualised → skip the key and say why in one line (auto mode without an isolation boundary removes the prompt safety net). Set it anyway only when the arguments explicitly ask.

Docs caveat: the settings reference claims `"auto"` is honored only in `~/.claude/settings.json`. This Config Repo uses it project-level anyway and that is the convention here; mention in the checklist that a session not picking it up means moving the key to `~/.claude/settings.json` by hand.

## Step 2 — disable notifications

Set `preferredNotifChannel: "notifications_disabled"`.

## Step 3 — Fable model, if available

Set `model: "claude-fable-5"`. An unavailable model falls back silently, so the key is safe to write regardless — but verify anyway so the checklist tells the truth:

```
claude -p ok --model claude-fable-5
```

Report "set and verified" on success, "set; account fell back" on failure. If the command cannot run at all (no CLI auth in this environment), just set the key and say the fallback rule makes it safe.

An argument naming another model (e.g. "model sonnet") replaces the model id in both the setting and the test.

## Step 4 — statusline

The script was deployed by `install.sh` to `.claude/scripts/statusline.sh`. Verify it exists; if it is missing, skip with a one-line pointer to re-run `install.sh`. Otherwise set, using the **absolute** path of the project's copy (never a path into the Config Repo):

```json
"statusLine": {
  "type": "command",
  "command": "bash /absolute/path/to/project/.claude/scripts/statusline.sh"
}
```

## Step 5 — run install-mattpocock

Invoke the `install-mattpocock` skill (deployed alongside this one), passing through any user arguments that concern it. If the Skill tool does not list it yet (fresh copy, session not reloaded), read `.claude/skills/install-mattpocock/SKILL.md` and follow it directly — same thing. It is itself safe to re-run.

## Wrap up

Finish with a one-line-per-step checklist: permission mode (set / skipped + why), notifications, model (set / unavailable), statusline, mattpocock. Remind the user that settings changes are picked up by a new session — `/reload-skills` does not apply them.

## Key table

| Setting | Key in `.claude/settings.local.json` | Value |
| --- | --- | --- |
| Permission mode | `permissions.defaultMode` | `"auto"` |
| Notifications | `preferredNotifChannel` | `"notifications_disabled"` |
| Model | `model` | `"claude-fable-5"` |
| Statusline | `statusLine` | `{"type": "command", "command": "bash <abs path>/.claude/scripts/statusline.sh"}` |
