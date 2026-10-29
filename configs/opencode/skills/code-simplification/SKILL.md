---
name: code-simplification
description: Reduce unnecessary complexity while preserving behavior and project conventions. Use for a requested refactor or simplifying the code changed in the current task.
---

# Code Simplification

Read behavior, tests and callers before removing or restructuring code. Prefer clear control flow, descriptive names, small pure helpers and existing shared components. Remove duplicate logic only when inputs, authorization, error behavior and side effects truly match.

Preserve public APIs, request/response shapes, role checks, session cleanup, state ordering and numeric precision. Keep network calls in services and hooks unconditional. Do not collapse distinct permission checks or replace careful atomic updates with read-modify-save convenience. Avoid dense ternaries and premature generalization.

Make one bounded transformation at a time and compare observable behavior. Run the affected regression checks and the project's required lint/build/formatting checks. Document a removed abstraction only if it helps explain the change. Leave unrelated code alone; do not claim fewer lines proves correctness.
