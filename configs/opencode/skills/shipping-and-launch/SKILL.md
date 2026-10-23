---
name: shipping-and-launch
description: Prepare an explicitly requested release with proportionate checks, deployment evidence and rollback. Use for release readiness or authorized deployment, not ordinary development edits.
---

# Shipping and Launch

Confirm target environment, source revision and intended user-visible behavior. Collect required test/lint/build/browser results and distinguish known baseline failures from regressions. Verify configuration names and health checks without exposing values.

Prepare a concrete deployment and rollback plan before any action outside the user's authorization. Do not deploy or promote merely because implementation is finished. When deployment is explicitly authorized, follow current platform/project instructions without inventing repeated approval gates.

Check compatibility of old/new application code and database changes. Prefer additive reversible rollout; never assume rolling back code undoes a destructive migration. Define observable success/failure thresholds and a rollback trigger proportional to the change.

After an authorized release verify the affected complete flow, error/latency signals and configuration-sensitive behavior such as cross-origin cookies. Local loopback tests do not prove deployed HTTPS behavior. Report revision, environment, executed checks and unresolved scope; never claim a deployment happened from a successful local build.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
