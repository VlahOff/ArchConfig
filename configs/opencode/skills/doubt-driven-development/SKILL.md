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
