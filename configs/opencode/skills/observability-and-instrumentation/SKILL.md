---
name: observability-and-instrumentation
description: Add or review useful logs, metrics and diagnostic events for a concrete production behavior or failure. Use when a feature lacks actionable runtime evidence.
---

# Observability and Instrumentation

Define the question first: which operation failed, how often, how long, or for whom within an authorized scope? Reuse existing logging and event conventions. Emit bounded structured fields such as event, correlation ID, operation, duration, safe result code and dependency status.

Keep secrets, passwords, cookies, CSRF tokens, email content and personal data out of logs. Avoid raw request bodies and high-cardinality identity labels in metrics. Do not turn expected validation errors into noisy alerts.

Select the smallest useful signal: request rate/error/duration for APIs, reconnect/revocation for SSE, bounded retry/failure for external work. Alert on a user-visible symptom with a clear owner and investigation path; avoid requiring a new monitoring platform for every edit.

Verify that success/failure paths emit expected fields, logging itself does not throw, redaction works and alert semantics match the operation. Distinguish diagnostic logs from application change events; denied business writes must not publish successful-change events. Report instrumentation added and any operational setup still required.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
