---
name: express-api-development
description: Implement or review Express routers, middleware, controllers, services, request validation and API regression coverage. Use for Node/Express endpoint changes in any repository.
---

# Express API Development

Read the current route mounting, middleware ordering, controller/service/persistence layers, error handling and owning package configuration. Identify Express version, CommonJS/ESM/TypeScript conventions and the actual authentication/access scheme. Reuse the existing architecture instead of assuming a particular file tree or protected mount table.

For each method/path define allowed actors, resource scope, explicit validated fields, result shape, safe errors and expected side effects. Mount authentication/authorization and applicable CSRF guards before handlers using the repository's established pattern. A protected route does not automatically validate a new schema or authorize each referenced record.

Derive the actor and ownership from authenticated server state; do not trust client-supplied role, tenant or grants. Keep controllers thin, business rules in the existing service layer and updates atomic where required. Reject unsafe keys, malformed IDs/types and oversized inputs. Keep safe HTTP methods free of business mutations and external delivery.

For cookie-authenticated mutations enforce the appropriate CSRF protection, including applicable auth/session endpoints. For a documented machine/webhook route use its designed authentication, payload and replay contract; never copy a bypass from another project or broaden an exception for convenience.

Test through the real mounted app and existing harness. Cover allowed success, anonymous/invalid identity, forbidden role/grant/resource scope, malformed input and applicable CSRF/replay failure. Assert denied operations cause no business writes, change events or outbound delivery. Use isolated fixtures and mocked providers. Run the repository's actual focused and completion commands and formatting checks; do not assume Node's test runner or a fixed test glob.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
