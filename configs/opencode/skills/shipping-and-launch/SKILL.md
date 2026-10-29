---
name: shipping-and-launch
description: Prepare an explicitly requested release with proportionate checks, deployment evidence and rollback. Use for release readiness or authorized deployment, not ordinary development edits.
---

# Shipping and Launch

Confirm target environment, source revision and intended user-visible behavior. Collect required test/lint/build/browser results and distinguish known baseline failures from regressions. Verify configuration names and health checks without exposing values.

Prepare a concrete deployment and rollback plan before any action outside the user's authorization. Do not deploy or promote merely because implementation is finished. When deployment is explicitly authorized, follow current platform/project instructions without inventing repeated approval gates.

Check compatibility of old/new application code and database changes. Prefer additive reversible rollout; never assume rolling back code undoes a destructive migration. Define observable success/failure thresholds and a rollback trigger proportional to the change.

After an authorized release verify the affected complete flow, error/latency signals and configuration-sensitive behavior such as cross-origin cookies. Local loopback tests do not prove deployed HTTPS behavior. Report revision, environment, executed checks and unresolved scope; never claim a deployment happened from a successful local build.
