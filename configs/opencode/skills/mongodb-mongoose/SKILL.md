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
