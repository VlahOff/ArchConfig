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

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
