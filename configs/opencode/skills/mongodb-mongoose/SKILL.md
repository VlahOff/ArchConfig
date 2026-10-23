---
name: mongodb-mongoose
description: Design and review MongoDB/Mongoose schemas, queries, indexes, atomic updates and migrations using existing data ownership and persistence conventions. Use for MongoDB/Mongoose changes.
---

# MongoDB and Mongoose

Read relevant schemas, services, authorization filters, indexes, package versions and deployment topology. Identify tenant/resource ownership, null/legacy semantics and lifecycle behavior from this repository; do not impose dashboard membership or specific role names.

Allowlist input fields and validate identifiers/types/enums/lengths. Never spread untrusted bodies into MongoDB queries/updates. Scope every applicable list/detail/update/delete/aggregation by authenticated server authority and verify referenced documents belong to the permitted scope. Null ownership must not silently become unrestricted access; establish intended legacy/public behavior before changes.

Use explicit projections and bounded pagination. Use lean only when document methods/hooks are unnecessary. Design compound indexes for observed filters/sorts and inspect query plans for actual bottlenecks. Enforce required uniqueness in the database and handle duplicate-key failures, rather than rely on racy find-then-create checks.

Use atomic update filters with expected state/version where conflicts matter. Check matched/modified outcomes and apply the repository's update-validation/hook conventions. Multi-document transactions require a supported topology; process-local queues do not coordinate across replicas/processes. Design partial-failure recovery when atomicity is unavailable.

Test with the existing isolated database harness: scope denial, malformed references, duplicates, concurrent writes, missing/legacy ownership, archived/deleted filtering and safe reruns. Do not connect test execution to real user data. For significant migrations use `deprecation-and-migration`; determine backup, dry-run, batching and resumability before authorized live execution.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
