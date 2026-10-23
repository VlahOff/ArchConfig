---
name: code-review-and-quality
description: Review a scoped diff for correctness, simplicity, architecture, security, performance and validation. Use for PRs or final implementation review, primarily in the main agent.
---

# Code Review and Quality

Read the requested behavior and current project rules, then the scoped diff, tests and affected callers. Respect any repository-specific exclusions during Git reads.

Review correctness (failure paths, races, stale state), readability (clear names, justified abstractions), architecture (reuse and boundaries), security (roles/grants/scope/CSRF/validation) and performance (bounded work, indexes, effect cleanup). Prioritize concrete new defects; separate existing unrelated failures. Inspect declared test coverage and actual output; a build does not establish security or runtime behavior.

Support each finding with file/line, trigger, impact and a feasible correction. Rank by severity. Do not invent problems, infer success from comments, or demand refactors unrelated to the change. Explain material test gaps and uncertainty.

Perform one review in the main agent by default. Do not run multiple reviewer models or repeat reviews merely to gain confidence. If a fix changes the artifact, recheck that behavior and dependent tests.

Report actionable findings first, followed by executed validation and uncovered scope. If no findings remain, state that with the review's limits. Apply the repository formatter and preserve the output its current rules require.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
