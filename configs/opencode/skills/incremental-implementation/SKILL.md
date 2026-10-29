---
name: incremental-implementation
description: Implement an authorized change in small verifiable vertical slices. Use for coding a feature or fixing behavior without broad refactors or agent fan-out.
---

# Incremental Implementation

Read the current contract and identify the smallest complete user path. Implement one slice, run focused checks, inspect behavior, and then continue the next dependent slice. Keep each intermediate change coherent; do not build all UI/API/database layers separately and defer integration until the end.

Reuse services/components and current framework versions. Add field validation and permission checks with each endpoint, not as a later phase. Preserve unrelated work, calculations and session behavior. Use the owning package formatter and follow its current formatting scope; preserve full-file output when repository rules require it.

Use the main agent for implementation and self-review. If one necessary specialist task is delegated, wait for it; do not launch explorer/frontend/backend/tester/reviewer together. Refer to `test-driven-development` for regression coverage and `git-workflow-and-versioning` for scoped commits when requested or required by project rules.

Run focused checks during iteration and the project's required completion checks once the final change is ready. Broaden or repeat only after new edits, failures or unresolved risks. Finish with exact evidence and remaining limitations; do not claim the build verifies authorization or visual layout.
