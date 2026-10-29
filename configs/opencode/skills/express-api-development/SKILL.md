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
