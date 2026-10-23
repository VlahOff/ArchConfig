---
name: deprecation-and-migration
description: Plan compatible API/schema changes, ownership assignment and resumable data backfills using the current project contracts. Use when replacing a supported interface or migrating existing data.
---

# Deprecation and Migration

Read existing schema, consumers, deployment compatibility and migration tools. Identify required old/new coexistence. Prefer additive changes with measurable completion and an explicit retirement path before removing a supported contract.

Determine migration authority and target ownership from the current project; do not impose special role names or organization/dashboard entities. Preserve access boundaries, archived/deleted filtering and retention rules. Null/legacy ownership must not silently become global visibility; establish the intended mapping and handle unknowns explicitly.

Prepare a read-only dry-run with selection criteria, target mapping, counts, conflicts and validation failures. Use bounded batches, dependency ordering, restart checkpoints, idempotency and partial-failure handling. Account for indexes, uniqueness, data volume and supported database transaction topology.

Distinguish code rollback from data rollback and prepare suitable backups or reversible mappings before live changes. Test on disposable fixtures: invalid/foreign targets, reruns, existing migrated records, partial failures and unauthorized callers.

Complete concrete scripts/plans/checks before requesting any required live-execution approval. Implementing a migration tool does not automatically authorize a production migration. Report actual changed/skipped/failed counts and the environment only after execution.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
