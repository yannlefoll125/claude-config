---
name: commit
description: Create git commits — invoke for EVERY commit, however it comes up: the user asks in any wording ("commit this", "make a commit"), the user approves a commit you offered, or committing is a step in your own work (then pass the intended files/scope as args). Bundles changes into logical commits with short "<topic>: <message>" messages; never pushes.
argument-hint: 'free-form instructions — omit to commit all current changes'
---

Turn the working tree into clean commits, on the current branch — invoking this skill is the authorization to commit here, so branch only if the user asks for one. Pushing is the user's own step: end after reporting the commits, never push.

## Project overrides

If `.claude/commit.md` exists in the project, read it first — its rules override the defaults below (message format, bundling, untracked-file policy, ...).

## Interpret the arguments

- Arguments given: instructions from whoever invoked the skill — the user's request, or your own intent when you invoked it yourself. Follow them (they may name files, a scope, a message, a bundling).
- No arguments, user typed bare `/commit`: commit every change, untracked files included. Judge which bundle each untracked file belongs to; a file that looks like scratch, secrets, or build output goes through the doubt gate below rather than into a commit.
- No arguments, you invoked it yourself mid-task: commit only the changes belonging to the work at hand; leave unrelated changes and the user's WIP untouched.

## Check identity

If `git config user.name` or `git config user.email` is empty, list the distinct authors of recent commits (`git log -5 --format='%an <%ae>'`) and ask the user which identity to commit under (offering a different one is fine). Persist the answer with `git config user.name` / `git config user.email` in this repo so the question never comes back. No commits to read from, or no user to ask (headless run): stop and report instead of guessing an identity.

## Plan the bundles

Review everything in scope: `git status`, `git diff`, `git diff --staged`, and the contents of untracked files being considered. Group the changes into logical bundles — one commit per independent change; a single commit is the common case, split only when the changes are genuinely unrelated. Bundle at file granularity: a file that mixes unrelated changes goes wholly into the most relevant bundle — note that in the report.

Each message: `<topic>: <message>` — topic is the area touched (a skill name, a script, docs); message uses a present-tense action verb; 1–2 sentences max, usually just the subject line (standard trailers don't count against this). Examples: `e2e: add playwright e2e tests`, `installer: refactor manifest sync`.

**Doubt gate**: if anything is unclear — whether an untracked file belongs in, how to bundle, what the invoker's instructions meant — present the plan (bundles, their files, their messages) and ask before committing anything. Otherwise commit directly.

## Commit

For each bundle in order: stage its files (`git add <files>`), then commit path-scoped (`git commit -m <message> -- <files>`) so anything pre-staged outside the bundle stays staged and uncommitted. A deliberate partial staging (a file whose staged hunks differ from its working tree) would be clobbered by a path-scoped commit — that's a doubt-gate case. Finish by verifying with `git status` and `git log` that every intended change is committed, then report the commits made and leave pushing to the user.
