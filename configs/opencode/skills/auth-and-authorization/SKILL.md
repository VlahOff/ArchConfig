---
name: auth-and-authorization
description: Implement or audit authentication, session lifecycle, CSRF, roles, permissions and resource/tenant isolation using the current repository security model. Use for access or account-security changes.
---

# Authentication and Authorization

## Establish the actual contract

Read route mounting, auth/session middleware, account/token services, current access rules and their regression tests. Identify cookie sessions, bearer tokens, OAuth or another scheme; distinguish authentication, role/capability, resource ownership, membership and account eligibility. Build a short actor/operation/resource matrix using the project's real role names. Do not invent an owner bypass, mandatory tenant dimension or feature-grant model.

## Preserve security boundaries

- Use authoritative server state for permission-sensitive decisions. Enforce them on every applicable read/write/export/search/stream path and referenced resource; UI visibility is presentation only.
- Scope applicable database reads and atomic writes by allowed actor/resource/tenant. Preserve non-disclosing errors and test live changes to roles, grants, memberships or eligibility.
- For cookie auth preserve HttpOnly/Secure/SameSite settings and the established CSRF defense. CORS/SameSite alone are not a general replacement; untrusted cookie/header equality alone is not robust double-submit protection. Trace login/refresh/logout/recovery boundaries too.
- For existing refresh-token rotation, replay protection, session revocation/versioning or absolute expiry, preserve their contracts and race behavior. Discover which mechanisms exist instead of assuming JWT refresh cookies everywhere.
- Reuse the existing frontend auth client, refresh coordination and sign-out cleanup. Keep credentials out of logs, artifacts and unintended browser persistence. Review token storage according to the actual scheme; do not introduce a second auth path incidentally.
- Design machine/webhook endpoints separately when explicitly required: credential validation, fail-closed configuration, payload bounds and suitable replay/idempotency protection. Never carry over a hardcoded endpoint exemption from another app.

## Verify

Test through the real mounted routes: allowed success, invalid/expired/revoked identity, forbidden capability/scope, foreign IDs and changed authorization during an existing session. For applicable CSRF failures use a writable actor and valid payload so a role denial cannot hide a missing CSRF guard. Test the chosen CSRF scheme's missing/forged/wrong-context cases and assert zero forbidden writes/outbound actions. For bearer/machine auth test its own credential and replay boundaries. Add relevant frontend session/cross-tab checks and distinguish local evidence from deployed HTTPS/cross-origin behavior.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
