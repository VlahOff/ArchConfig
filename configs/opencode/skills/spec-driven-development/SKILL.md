---
name: spec-driven-development
description: Clarify significant ambiguous feature requirements and record testable behavior before coding. Use for new capabilities or consequential scope/access decisions, not every multi-file change.
---

# Spec-Driven Development

Read the task and current project contracts. Reuse an existing spec if it covers the behavior. Ask only unresolved consequential questions; avoid a questionnaire when requirements are already explicit.

Define objective, actors/permissions, data ownership, input/output behavior, happy/failure paths, dependencies, scope exclusions and acceptance criteria. Separate several independently useful capabilities when a request spans them. Preserve the installed stack and identify any proposed framework needing explicit approval under project rules.

Use a short in-session spec for modest work; save a descriptive document in the project's convention for larger work. Do not overwrite unrelated incomplete plans or use files the repository reserves for user-managed work.

Proceed into a sequential implementation plan when the user authorized implementation and material questions are resolved. Do not require human approval after specify/plan/tasks/implementation for routine known work. If changing access or data-retention semantics without a clear instruction, resolve that choice before dependent edits.

Keep the spec synchronized with the final behavior and verify each acceptance criterion. A documented assumption is not a verified implementation.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
