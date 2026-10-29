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
