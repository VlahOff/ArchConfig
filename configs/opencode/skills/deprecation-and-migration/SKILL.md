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
