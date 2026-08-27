---
status: accepted
---

# The Config Repo is public, and is delivered as a plugin from a git marketplace

The repository is public on GitHub, so a Sandbox can read it with no credential at all.
Delivery uses the plugin mechanism: `.claude-plugin/marketplace.json` at the repo root
makes the repo a git-based marketplace, and the Config Plugin is installed from it.

Bootstrap is three typed commands, with a human present:

```
/plugin marketplace add https://github.com/yannlefoll125/claude-config
/plugin install claude-config@claude-config
/setup
```

## Considered Options

- **A plain install script** (`curl … | bash`, or clone-and-copy) — rejected. The plugin
  mechanism already loads skills, hooks and output styles in place and gives
  `/plugin update` for free; a script would have to reimplement both.
- **Keeping the repo private** — rejected. Every route into a private repo costs either a
  credential inside the Sandbox or a git server running on the Host. That is a permanent
  price for files that contain nothing secret.
- **A one-line shell bootstrap** to register the marketplace — rejected as a script to
  maintain against Claude Code's settings format, replacing three lines pasted once per
  Sandbox.

## Consequences

**Nothing secret may ever enter this repository.** The Payload is world-readable and git
history is permanent. This is now the single security rule the design depends on.

A git-based marketplace clones the whole repository, so relative sources resolve. That is
why `marketplace.json` sits at the repo root and can point at `"source": "./dist"`. A
URL-based marketplace would fetch only the JSON and fail to find the plugin files.
