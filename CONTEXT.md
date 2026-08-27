# Claude Config

A public repository holding one person's Claude Code preferences, plus the means to bring
a fresh Sandbox up to that configured state.

## Language

**Host**:
The physical machine the user works from. Holds the git credential and is the only place
changes are pushed from.
_Avoid_: machine, laptop

**Sandbox**:
The isolated environment Claude Code actually runs in, launched from a Host. Holds no
credential of any kind. The design does not care which hypervisor or container runtime
backs it — only whether it is virtualised at all.
_Avoid_: instance, container, VM, box

**Config Repo**:
This repository — the single source of the user's Claude Code preferences, and the source
of the machinery that installs them.
_Avoid_: dotfiles, config directory, collection

**Config Plugin**:
The Claude Code plugin published from the Payload. It is what a Sandbox installs, and it
carries the `/setup` skill along with every Carried Artifact.
_Avoid_: entry point plugin, bootstrapper, installer

**Payload**:
`dist/` — everything that ships, and nothing else. Hand-authored and committed, despite
the name. It is also the Config Plugin's root. Anything outside it is tooling or
documentation and never reaches a Sandbox.
_Avoid_: bundle, package, build output

**Artifact**:
A single preference living in the Payload. Every Artifact is either Carried or Deployed;
there is no third kind.
_Avoid_: config file, asset, resource

**Carried Artifact**:
An Artifact the plugin mechanism loads in place, with no copying — skills, hooks, agents,
output styles. It updates when the Config Plugin updates.
_Avoid_: bundled artifact, native artifact

**Deployed Artifact**:
An Artifact no plugin can express, so `/setup` must copy it into a Target — the statusline
script, settings keys, and the instructions file. It does not update when the Config
Plugin updates, which is why Staleness exists.
_Avoid_: copied artifact, installed artifact

**Target**:
The project directory `/setup` writes Deployed Artifacts into. Always the project, never
the user's home directory.
_Avoid_: destination, install dir

**Deploy**:
Copying Deployed Artifacts into a Target, rewriting any paths so they point at the copies
rather than at the plugin, and excluding every written path from the Target's git.
_Avoid_: install, sync, apply, link

**Bootstrap**:
Taking a fresh Sandbox from zero to the configured state: add the marketplace, install the
Config Plugin, run `/setup`. Needs no credential.
_Avoid_: install, provision, setup

**Authoring**:
Changing preferences, which happens in the Config Repo and is published by pushing from
the Host. Its counterpart is Consuming — using preferences in any other project, which
needs no credential and no write access.
_Avoid_: editing config, updating config

**Staleness**:
The state of a Target whose Deployed Artifacts are older than the installed Config Plugin.
It is invisible without help, because updating the plugin does not touch them.
_Avoid_: drift, out of date, unsynced
