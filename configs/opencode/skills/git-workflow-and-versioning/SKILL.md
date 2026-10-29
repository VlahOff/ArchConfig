---
name: git-workflow-and-versioning
description: Review, stage and commit a scoped change while respecting project exclusions and preserving unrelated work. Use when Git operations are requested or required by repository rules.
---

# Git Workflow and Versioning

Read branch/status and repository instructions. Identify protected files and user-managed work before broad reads. Use explicit task-owned path lists and exclusion pathspecs appropriate to this repository; never invent a universal filename exclusion or stage all files blindly.

Inspect the final scoped diff and run `git diff --check` on permitted changed paths. Apply the repository formatter and retain its required output. Compare relevant files with HEAD to distinguish baseline whitespace/tooling failures from introduced ones; report both honestly. Do not normalize unrelated manifests/lockfiles incidentally.

Stage only authorized task paths and inspect the staged diff. Follow current commit conventions and describe the final behavior. Commit when requested or required; implementation alone does not authorize push, merge, publish or shared-history changes.

Do not discard unstaged work, force-push, reset hard or amend someone else's commit to tidy a diff. Use a separate worktree for operations requiring checkout changes. Use temporary body files for multiline descriptions instead of interpolating untrusted shell text. Report the branch/revision only after the operation succeeds.
