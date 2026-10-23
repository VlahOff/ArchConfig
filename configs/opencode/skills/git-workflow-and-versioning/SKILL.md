---
name: git-workflow-and-versioning
description: Review, stage and commit a scoped change while respecting project exclusions and preserving unrelated work. Use when Git operations are requested or required by repository rules.
---

# Git Workflow and Versioning

Read branch/status and repository instructions. Identify protected files and user-managed work before broad reads. Use explicit task-owned path lists and exclusion pathspecs appropriate to this repository; never invent a universal filename exclusion or stage all files blindly.

Inspect the final scoped diff and run `git diff --check` on permitted changed paths. Apply the repository formatter and retain its required output. Compare relevant files with HEAD to distinguish baseline whitespace/tooling failures from introduced ones; report both honestly. Do not normalize unrelated manifests/lockfiles incidentally.

Stage only authorized task paths and inspect the staged diff. Follow current commit conventions and describe the final behavior. Commit when requested or required; implementation alone does not authorize push, merge, publish or shared-history changes.

Do not discard unstaged work, force-push, reset hard or amend someone else's commit to tidy a diff. Use a separate worktree for operations requiring checkout changes. Use temporary body files for multiline descriptions instead of interpolating untrusted shell text. Report the branch/revision only after the operation succeeds.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
