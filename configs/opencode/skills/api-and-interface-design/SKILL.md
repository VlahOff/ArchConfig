---
name: api-and-interface-design
description: Design or change API contracts, validation, pagination and error semantics. Use for endpoints or shared interfaces; preserve current client and route conventions.
---

# API and Interface Design

1. Read caller and server paths before designing a contract. Document method/path, allowed actor, scope, explicit input fields, result shape and error semantics.
2. Extend existing contracts compatibly; do not rename routes or introduce a second HTTP client incidentally. For Express use `express-api-development`; reuse the current HTTP client and verify supported methods and signatures before extending it.
3. Bound pagination, sorting, filtering and payload sizes; allowlist supported fields and reject unsafe keys. Separate write inputs from public outputs; never serialize a whole user/document by default.
4. Authorize referenced resources, not only the parent endpoint. Scope reads and atomic writes by current identity and ownership.
5. Keep safe HTTP methods read-only. Design duplicate/retry behavior before adding side effects. Enforce idempotency atomically when required; never merely accept a key or replay one tenant's cached response to another.
6. Return existing stable error codes and non-disclosing forbidden/not-found behavior. Keep internal stack traces and secrets private.
7. Test successful requests and relevant malformed, anonymous, forbidden, cross-tenant and duplicate cases through the mounted application. Verify consumers against the final contract.

Use the project's established JavaScript/JSDoc or TypeScript conventions; do not migrate languages merely to express an interface. Use `deprecation-and-migration` only when removing a supported contract.
