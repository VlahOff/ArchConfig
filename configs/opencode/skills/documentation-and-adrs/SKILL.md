---
name: documentation-and-adrs
description: Update implementation guides, API docs or architecture decisions after a meaningful contract change. Use for requested documentation or shared architecture changes.
---

# Documentation and ADRs

Read existing conventions and verify claims against current source. Update the existing guide rather than creating duplicate documentation. Document purpose, inputs/outputs, permission boundaries, side effects, errors, operational prerequisites and runnable commands when they matter.

Maintain the existing implementation, architecture and authentication documentation when those contracts change; respect any protected-file rules. Do not include actual environment values, tokens or real user data.

Write an ADR only for a meaningful tradeoff: context, options, decision, consequences and status. Match the project's naming/location convention; small implementation details need a useful comment, not an ADR.

Verify all local paths, anchors, command working directories and examples. State date/branch for any snapshot and tell future agents to re-read current sources. Do not report an old test count as a current run. Keep prose changes within scope; do not require an application build solely for documentation.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
