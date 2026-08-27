---
status: accepted, narrowed by ADR-0003
---

# Bootstrap prompts for a PAT and stores it with git credential-store

> **Narrowed by [ADR-0003](./0003-vendored-local-marketplace.md).** A PAT is no longer needed to Bootstrap a Sandbox — only on a Host cloning the Config Repo for the first time, and when Authoring config changes that must be pushed. The storage decision below still stands wherever a PAT is in play.


A fresh Host or Sandbox has no GitHub credential of any kind, so Bootstrap prompts the user to paste a fine-grained PAT (scoped to this repo only, contents read+write) copied from their password manager. On a Persistent Sandbox it is handed to `git credential-store`, which writes `~/.git-credentials` at mode 600, so the paste happens once per sandbox lifetime. On an Ephemeral Sandbox nothing is stored and the PAT is used only for that run.

## Considered Options

- **gnome-keyring + git-credential-libsecret** — rejected. Fedora Cloud Edition ships `secret-tool` but no keyring daemon (`secret-tool store` fails with "The name is not activatable"), and `git-credential-libsecret` is not built. Installing it would mean typing a keyring password on every boot, trading one paste-per-lifetime for one unlock-per-boot.
- **Never store, prompt every time** — rejected as too much friction on the Persistent Sandbox, where home survives reboots anyway.

## Consequences

Plaintext on disk protects nothing against someone who obtains the disk image. This is accepted deliberately: Claude Code runs as the same user and can read any credential store once it is unlocked, so the storage mechanism was never the security boundary. **PAT scope is the only real control** — keep it fine-grained and limited to this repository.
