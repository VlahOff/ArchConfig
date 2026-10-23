---
name: using-agent-skills
description: Select relevant engineering skills for an OpenCode task; use at session start or when choosing a workflow. Prefer direct execution and minimal context.
---

# Using Agent Skills

Select one primary skill and, when useful, one supporting skill. Read more only when the task crosses another boundary. Use OpenCode's available skill tool by the exact discovered name; do not assume a slash command exists. Apply skill instructions within the main agent.

| Work | Skill |
| --- | --- |
| Vague idea | idea-refine |
| Unclear significant requirements | spec-driven-development |
| Large task with clear requirements | planning-and-task-breakdown |
| Implementation | incremental-implementation |
| React/Vite/Redux changes | react-vite-development |
| Express endpoints | express-api-development |
| MongoDB schema/query changes | mongodb-mongoose |
| Authentication, roles, grants or ownership | auth-and-authorization |
| General UI work | frontend-ui-engineering |
| General API contracts | api-and-interface-design |
| Regression coverage | test-driven-development |
| Browser runtime investigation | browser-testing-with-devtools |
| Multilingual UI verification | multilingual-browser-qa |
| Failures | debugging-and-error-recovery |
| Review | code-review-and-quality |
| Question a risky assumption | doubt-driven-development |
| Simplification | code-simplification |
| Security | security-and-hardening |
| Measured slowness | performance-optimization |
| Context or version-specific APIs | context-engineering / source-driven-development |
| Git, CI or migration | git-workflow-and-versioning / ci-cd-and-automation / deprecation-and-migration |
| Documentation, telemetry or release | documentation-and-adrs / observability-and-instrumentation / shipping-and-launch |

For a small fix, read the relevant files, implement, run focused checks, and report. For a significant feature, clarify acceptance criteria, make a short sequential plan, implement slices, then verify. Do not create plan/spec files for every edit. Ask only when missing information materially changes behavior, permission or data ownership; continue independent work.

Finish with changed behavior, exact validation results, and material remaining limitations. Follow the current project definition of done rather than a nonexistent shared checklist.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
