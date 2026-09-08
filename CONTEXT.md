# Claude Config

A public repository holding one person's Claude Code preferences, plus the machinery that
installs them into any project and keeps those copies current.

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

**Payload**:
The root directories that ship — `skills/`, `output-styles/`, `scripts/` — everything an
Install copies, and nothing else. Hand-authored and committed. Anything outside it is
tooling or documentation and never reaches a Target.
_Avoid_: bundle, package, dist, build output

**Artifact**:
A single preference living in the Payload — a skill, a script, an output style. Every
Artifact reaches a Target by being copied, never by being loaded in place, and must work
identically from the Host and from a Sandbox.
_Avoid_: config file, asset, resource

**Target**:
The project directory an Install writes into. Always the project's `.claude/`, never the
user's home directory. The Config Repo is itself a Target of its own Payload.
_Avoid_: destination, install dir

**Install**:
Copying the Payload into a Target, recording what shipped in the Manifest, and subscribing
the Target — `claude-config-install`.
_Avoid_: deploy, sync, apply, link

**Manifest**:
The record an Install leaves in the Target: a version stamp plus the list of files that
shipped. Only files the previous Manifest lists are ever deleted, which is what keeps the
Target's own files in the managed directories safe.
_Avoid_: lockfile, inventory, receipt

**Subscriber**:
A Target remembered at Install time, per environment, so that a later Push reaches it. A
Subscriber whose path has vanished is skipped with a warning, not unsubscribed.
_Avoid_: consumer, registered project

**Push**:
Re-running Install into every Subscriber at once. It writes into projects beyond the one
being worked on, so it is always the user's own step, never an agent's.
_Avoid_: publish, broadcast, deploy-all

**Setup**:
The in-session step after an Install — `/setup-claude-config` — that wires the copies up:
base settings written into the Target's `.claude/settings.local.json`. Safe to re-run.
_Avoid_: configure, init, bootstrap

**Consuming**:
Using the preferences in a project: Install, then Setup. Needs no credential and no write
access to the Config Repo. Its counterpart is Authoring.
_Avoid_: onboarding, adopting

**Authoring**:
Changing preferences, which happens against the Payload in the Config Repo — the Config
Repo's own installed copies are synced in the same commit. Reaching every other Target is
a Push.
_Avoid_: editing config, updating config

**Staleness**:
The state of a Target whose installed copies are older than the Config Repo's Payload.
Nothing in the Target detects it; only the Manifest's version stamp betrays it, and only
the next Install or Push cures it.
_Avoid_: drift, out of date, unsynced

**Config Plugin**:
A prospective future distribution vector, not part of the current design: publishing the
Payload as a Claude Code plugin, so Artifacts load in place and update with the plugin
instead of being copied and going stale. Earlier ADRs explored this shape; the terms they
use (Carried and Deployed Artifacts, Deploy, Bootstrap) belong to that design and are not
current vocabulary.
_Avoid_: entry point plugin, bootstrapper, installer
