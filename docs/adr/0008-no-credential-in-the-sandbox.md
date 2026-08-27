---
status: accepted
---

# The Sandbox holds no credential; publishing happens from the Host

Reading needs nothing, because the repository is public. Pushing needs a credential, and
that credential lives only on the Host. The project directory is mounted into the Sandbox
from the Host, so the agent's edits are already visible there — the user commits and
pushes from the Host.

## Considered Options

- **A fine-grained PAT stored in the Sandbox** by `git credential-store` — rejected. It
  places a push-capable token in plaintext beside an agent running in auto permission
  mode, in order to save one command run by a human who is present anyway.

## Consequences

The agent cannot complete the publish loop. The last step is the user's.

Two development paths exist, and both are worth keeping:

- **`claude --plugin-dir dist`** loads the Payload straight from the working tree. Fast
  iteration on skill logic — `SKILL.md` edits apply live mid-session, other components
  need `/reload-plugins`. A broken edit affects only the session launched with that flag.
- **Commit, push, `/plugin update`** exercises real delivery, so it catches packaging
  errors the flag never will — a bad `plugin.json`, a wrong relative path, a marketplace
  that will not refresh. A broken change reaches every Sandbox that updates, and is backed
  out by installing a previous version.
