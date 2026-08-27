---
status: accepted
---

# Config Repo is a mechanism for bootstrapping Collections; local serving is a later source

The Config Repo is two separable things: a **mechanism** for bootstrapping a Claude Code environment from a Collection, and **one Collection** that happens to be the author's own preferences. Treating them as one thing was an accident of there being only one Collection so far.

Delivery is therefore a *source* behind the mechanism, not a fixed property of it. A Collection reachable over the public internet needs no infrastructure at all. A Collection that must stay private, or a Sandbox with no internet, needs the containerised host git server of [ADR-0005](./0005-host-served-git-marketplace.md) — which is deferred rather than dropped, and becomes one source among several.

## Why defer rather than build

The host server carries real, permanent cost: a container to keep running, a service dependency that breaks Bootstrap when down, a network hole from Sandbox to Host, and a Host address that is backend-specific and — under Hyper-V — not even stable across reboots. None of that is paid by a Collection that is simply fetchable.

Deferring keeps that cost until a Collection actually requires privacy or offline operation, rather than paying it for all Collections because one might.

## Consequences

- **The mechanism must not assume its source.** Anything that hardcodes a single marketplace URL, or assumes the Config Repo is the only Collection, is a future migration. `/setup` should take the Collection it is configuring from, not infer it.
- **`0.y.z`, `dist/` layout, `/setup` behaviour and the Artifact split are all mechanism**, not Collection, and survive any change of source.
- **Multiple Collections become plausible** — a personal one and a work one, or a shareable public mechanism with a private Collection behind it. The glossary term exists so that possibility is not designed out by accident.
- **ADR-0005 stays in the trail as deferred, not superseded.** Its content is the implementation guide for the private and offline cases when they arrive.
