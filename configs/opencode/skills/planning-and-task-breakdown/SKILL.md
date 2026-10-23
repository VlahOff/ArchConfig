---
name: planning-and-task-breakdown
description: Break a substantial, clearly defined change into small sequential tasks with dependencies and verification. Skip for obvious small edits.
---

# Planning and Task Breakdown

1. Read requirements, relevant source and existing plans. Preserve incomplete work; update a plan for the same task, or use a separate descriptive filename for unrelated work.
2. Identify dependencies and high-risk unknowns. Split by complete user behavior: storage, API and UI together when applicable.
3. For each task record outcome, acceptance criteria, likely files, dependencies and concrete verification command.
4. Order tasks sequentially. Independent tasks may still be completed by the main agent; independence is not a reason to launch several agents.
5. Use an in-session checklist for modest work. For long work use the project's existing plan location or `tasks/<feature>-plan.md`. Respect protected files and preserve existing user-managed task lists.
6. Continue implementation when the user requested it and the required decisions are known. Pause for unresolved product/access decisions or actions outside authorization, not a mandatory review after every phase.

Task template: `Outcome -> files -> prerequisites -> success/failure criteria -> check command`. Check that every task can be verified independently and that prerequisites come first. A task count is not an agent count.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
