---
name: context-engineering
description: Gather and compress task-relevant source, rules and evidence for local-model work. Use when context is large, stale, contradictory or repeatedly reloaded.
---

# Context Engineering

Load context in order: user task -> repository rules -> relevant spec/contract -> exact implementation and callers -> focused test/error output. Use `rg` and narrow file reads; honor repository-specific protected-file exclusions.

Track proven facts separately from assumptions. Re-read authoritative current files when a cached summary conflicts. Preserve access rules, module contracts, acceptance criteria, decisions and unresolved failures during compaction; omit repeated logs and unrelated files. Do not load every skill, whole repository, all MCP output or environment secrets.

Maintain a restartable checkpoint for long tasks with branch/commit, changed paths, commands/results, next action and unresolved question. Use a scoped project-approved notes path and avoid overwriting another task's notes.

Use the same local model and direct tools. Context management is not a reason to spawn several explorer agents. Summarize a large tool result before expanding another section; stop re-reading once the needed evidence is present.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
