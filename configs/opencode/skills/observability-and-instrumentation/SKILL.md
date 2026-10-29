---
name: observability-and-instrumentation
description: Add or review useful logs, metrics and diagnostic events for a concrete production behavior or failure. Use when a feature lacks actionable runtime evidence.
---

# Observability and Instrumentation

Define the question first: which operation failed, how often, how long, or for whom within an authorized scope? Reuse existing logging and event conventions. Emit bounded structured fields such as event, correlation ID, operation, duration, safe result code and dependency status.

Keep secrets, passwords, cookies, CSRF tokens, email content and personal data out of logs. Avoid raw request bodies and high-cardinality identity labels in metrics. Do not turn expected validation errors into noisy alerts.

Select the smallest useful signal: request rate/error/duration for APIs, reconnect/revocation for SSE, bounded retry/failure for external work. Alert on a user-visible symptom with a clear owner and investigation path; avoid requiring a new monitoring platform for every edit.

Verify that success/failure paths emit expected fields, logging itself does not throw, redaction works and alert semantics match the operation. Distinguish diagnostic logs from application change events; denied business writes must not publish successful-change events. Report instrumentation added and any operational setup still required.
