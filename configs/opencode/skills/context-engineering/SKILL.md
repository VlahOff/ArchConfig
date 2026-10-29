---
name: context-engineering
description: Gather and compress task-relevant source, rules and evidence for local-model work. Use when context is large, stale, contradictory or repeatedly reloaded.
---

# Context Engineering

Load context in order: user task -> repository rules -> relevant spec/contract -> exact implementation and callers -> focused test/error output. Use `rg` and narrow file reads; honor repository-specific protected-file exclusions.

Track proven facts separately from assumptions. Re-read authoritative current files when a cached summary conflicts. Preserve access rules, module contracts, acceptance criteria, decisions and unresolved failures during compaction; omit repeated logs and unrelated files. Do not load every skill, whole repository, all MCP output or environment secrets.

Maintain a restartable checkpoint for long tasks with branch/commit, changed paths, commands/results, next action and unresolved question. Use a scoped project-approved notes path and avoid overwriting another task's notes.

Use the same local model and direct tools. Context management is not a reason to spawn several explorer agents. Summarize a large tool result before expanding another section; stop re-reading once the needed evidence is present.
