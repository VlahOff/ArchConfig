---
name: doubt-driven-development
description: Challenge high-risk assumptions or nontrivial security, data-integrity and concurrency claims with counterexamples. Use for uncertain decisions, without mandatory reviewer agents.
---

# Doubt-Driven Development

1. State one falsifiable claim about the changed behavior and its contract.
2. Isolate the smallest artifact that supports it: route, query, effect, state transition or diff.
3. In the main agent, seek a counterexample: foreign tenant, changed role, stale session, duplicate submit, failed write, out-of-order response, or missing prerequisite.
4. Trace the actual code path and use an existing test or add a focused regression test when behavior warrants it. Treat finding labels as hypotheses until supported by evidence.
5. Reconcile valid findings and stop after verification. Do not repeat review of an unchanged artifact or call other models automatically.

Use one independent reviewer only when it is necessary for a concrete unresolved risk or explicitly requested. Give that reviewer the artifact and contract, not the desired verdict. Wait for completion before further delegation. Never require a reviewer per decision, cross-model escalation, or nested agents. Label self-review accurately; it is not an independent fresh-context review.

Output: claim, counterexample investigated, evidence, resolution and remaining uncertainty. Skip for cosmetic edits with no material behavioral uncertainty.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
