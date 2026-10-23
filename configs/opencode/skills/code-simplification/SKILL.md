---
name: code-simplification
description: Reduce unnecessary complexity while preserving behavior and project conventions. Use for a requested refactor or simplifying the code changed in the current task.
---

# Code Simplification

Read behavior, tests and callers before removing or restructuring code. Prefer clear control flow, descriptive names, small pure helpers and existing shared components. Remove duplicate logic only when inputs, authorization, error behavior and side effects truly match.

Preserve public APIs, request/response shapes, role checks, session cleanup, state ordering and numeric precision. Keep network calls in services and hooks unconditional. Do not collapse distinct permission checks or replace careful atomic updates with read-modify-save convenience. Avoid dense ternaries and premature generalization.

Make one bounded transformation at a time and compare observable behavior. Run the affected regression checks and the project's required lint/build/formatting checks. Document a removed abstraction only if it helps explain the change. Leave unrelated code alone; do not claim fewer lines proves correctness.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
