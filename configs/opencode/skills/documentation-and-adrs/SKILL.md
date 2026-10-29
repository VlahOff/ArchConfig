---
name: documentation-and-adrs
description: Update implementation guides, API docs or architecture decisions after a meaningful contract change. Use for requested documentation or shared architecture changes.
---

# Documentation and ADRs

Read existing conventions and verify claims against current source. Update the existing guide rather than creating duplicate documentation. Document purpose, inputs/outputs, permission boundaries, side effects, errors, operational prerequisites and runnable commands when they matter.

Maintain the existing implementation, architecture and authentication documentation when those contracts change; respect any protected-file rules. Do not include actual environment values, tokens or real user data.

Write an ADR only for a meaningful tradeoff: context, options, decision, consequences and status. Match the project's naming/location convention; small implementation details need a useful comment, not an ADR.

Verify all local paths, anchors, command working directories and examples. State date/branch for any snapshot and tell future agents to re-read current sources. Do not report an old test count as a current run. Keep prose changes within scope; do not require an application build solely for documentation.
