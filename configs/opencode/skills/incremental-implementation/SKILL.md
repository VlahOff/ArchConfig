---
name: incremental-implementation
description: Implement an authorized change in small verifiable vertical slices. Use for coding a feature or fixing behavior without broad refactors or agent fan-out.
---

# Incremental Implementation

Read the current contract and identify the smallest complete user path. Implement one slice, run focused checks, inspect behavior, and then continue the next dependent slice. Keep each intermediate change coherent; do not build all UI/API/database layers separately and defer integration until the end.

Reuse services/components and current framework versions. Add field validation and permission checks with each endpoint, not as a later phase. Preserve unrelated work, calculations and session behavior. Use the owning package formatter and follow its current formatting scope; preserve full-file output when repository rules require it.

Use the main agent for implementation and self-review. If one necessary specialist task is delegated, wait for it; do not launch explorer/frontend/backend/tester/reviewer together. Refer to `test-driven-development` for regression coverage and `git-workflow-and-versioning` for scoped commits when requested or required by project rules.

Run focused checks during iteration and the project's required completion checks once the final change is ready. Broaden or repeat only after new edits, failures or unresolved risks. Finish with exact evidence and remaining limitations; do not claim the build verifies authorization or visual layout.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
