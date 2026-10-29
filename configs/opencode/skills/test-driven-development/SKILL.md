---
name: test-driven-development
description: Add meaningful regression coverage with the repository's existing unit, integration and browser harnesses. Use for behavioral bugs, endpoints, security boundaries and important workflows.
---

# Test-Driven Development

Discover manifests, workspace boundaries, package scripts, installed runner/configuration, fixtures and test prerequisites. Reuse the actual Node test runner, Vitest, Jest, Playwright or other established harness; do not prescribe one or add a competing framework incidentally. Check whether lint/build/test scripts exist and where they run.

For a behavioral bug create the smallest regression test, confirm it fails for the intended cause, implement the fix and rerun. Assert observable outcomes rather than mirroring implementation. Do not write new tests for trivial reversible prose/formatting changes unless repository rules require them.

Use synthetic identities and disposable storage/configuration; mock outbound delivery/providers. For access or input boundaries test the real route/middleware stack and denied-operation side effects, alongside allowed success. Inspect helper behavior before assuming it supplies cookies/headers, transactions or setup teardown. A 403 from the wrong guard does not prove the expected guard ran.

Cover relevant races, stale sessions, scope changes, retries and recovery. For browser checks use stable role/label/test-ID selectors and condition waits instead of arbitrary sleeps. Keep fixtures isolated and teardown deterministic. Use supported runner concurrency controls when resources require sequential execution.

Run focused checks while iterating and the repository's required completion checks after the final change. Broaden/repeat only for new changes, failures or unresolved risks. Report exact commands/results, prerequisites and skipped behavior; never present historical test counts as current evidence.
