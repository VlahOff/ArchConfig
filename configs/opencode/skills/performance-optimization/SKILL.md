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
