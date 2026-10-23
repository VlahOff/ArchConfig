---
name: performance-optimization
description: Measure and improve an actual frontend, API, query or worker bottleneck. Use for observed slowness or regressions, preserving correctness and access control.
---

# Performance Optimization

1. Record a repeatable baseline: dataset, operation, environment, warm/cold state, latency and resource use. Use the available profiler/query plan rather than guessing.
2. Find the dominant cost: excess React renders, expensive synchronous calculations, bundle work, N+1 queries, unbounded results, scans or external I/O.
3. Make one measured change. Reuse the project's existing worker interface for expensive computations and preserve domain calculations, cancellation and stale-result handling.
4. For MongoDB, scope queries first; evaluate compound indexes against real filters/sorts, cap results and use projections. Use lean only when document methods/hooks are unnecessary.
5. Cache only with a defined invalidation rule. Include organization/dashboard/user scope where applicable; do not reuse authorization decisions or stale sessions as authority. Bound retry/backoff and cache size.
6. Repeat the same measurement and required regression tests; keep the change only when it improves the target without changing behavior. Record inconclusive/reverted attempts.

Use browser Core Web Vitals as appropriate: LCP <=2.5s, INP <=200ms, CLS <=0.1. A local synthetic run is not proof of deployed real-user performance. Do not add memoization, dependencies or infrastructure merely because they might be faster.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
