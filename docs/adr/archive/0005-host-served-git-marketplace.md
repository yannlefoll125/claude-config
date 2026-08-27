---
status: deferred — see ADR-0006
---

# A containerised host git server is the only delivery route

> **Deferred by [ADR-0006](./0006-collections-and-deferred-local-serving.md).** Everything below remains sound and is the design to build if a Collection must stay private or a Sandbox must run without internet. It is not the first thing built, because a publicly reachable Collection needs none of it.

A container on the Host serves a bare clone of the Config Repo over read-only dumb HTTP git. A Sandbox adds it as an ordinary git-based marketplace and installs the Config Plugin from it:

```
/plugin marketplace add http://192.168.122.1:8765/claude-config.git
```

This supersedes [ADR-0003](./0003-vendored-local-marketplace.md). Vendoring is dropped entirely — there is no `.marketplace/`, no `setupMarketplace.sh`, no per-project registration, and no version staging.

## Why

Vendored copies could not self-update. A project Sandbox had only its project mount, so new configuration had to be pushed by the Host and re-vendored per project. Serving over the Host's network makes updates a normal `/plugin update`, while still requiring no credential in the Sandbox.

**Dumb HTTP git, not a REST API and not a URL marketplace.** A URL-based marketplace downloads only `marketplace.json` and never the plugin files, so a relative `"source": "./dist"` fails with "path not found". A git-based marketplace clones the whole repository, so relative paths work — which is also why `.claude-plugin/marketplace.json` sits at the repo root rather than inside `dist/`.

## Consequences

- **The version staging pipeline disappears.** Claude Code keys updates on `plugin.json`'s `version`, which is committed like anything else, so there is nothing to stage and no `out/gen/target/<version>/`.
- **`update-server-info` is load-bearing.** Dumb HTTP has no server-side git process; clients read a pre-generated ref index. The container's entrypoint clones-or-fetches from the read-only `/src` mount, runs `git update-server-info`, then serves. A stale index means Sandboxes silently see an old HEAD.
- **Bind to the sandbox gateway, never `0.0.0.0`.** `ports: ["192.168.122.1:8765:8000"]`. Publishing broadly would make the whole config repo readable by anything on the LAN.
- **The address is backend-specific, and must never be baked into committed config.** See [Backends](#backends) below.
- **Read-only, deliberately.** A writable service would let an agent in any Sandbox rewrite global configuration. Authoring stays in the Config Repo with the PAT.
- **The service is a dependency.** Vendored copies worked offline forever; if the container is down, no Sandbox can install or update. Accepted as the cost of self-service updates.
- **Per-project pinning is lost.** Every Sandbox tracks the served HEAD unless tags are served and pinned deliberately.

## Backends

**libvirt/KVM is the reference backend** and the only one treated as supported. The Host is reachable at `192.168.122.1`, the default network's NAT gateway.

**Docker is untested.** On Linux the Host is `172.17.0.1` on the default bridge, or `host.docker.internal` with `--add-host=host.docker.internal:host-gateway`. Neither has been verified against a running Marketplace Service. Treat as unsupported until it is.

**Hyper-V is required but not yet designed**, and it is the awkward one: the Default Switch assigns its subnet dynamically and **can change across Host reboots**, so no address can be written down once and trusted. An Internal switch with a static Host address avoids this at the cost of manual network setup.

Because of Hyper-V, the address cannot be a constant anywhere. The Sandbox must resolve it at Bootstrap — either from its own default route (the Host *is* the gateway under every NAT-style backend) or from a value the launcher injects. A guest bridged directly onto the LAN breaks the default-route assumption, since the gateway is then the router rather than the Host.
