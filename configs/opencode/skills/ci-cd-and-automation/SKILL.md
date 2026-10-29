---
name: ci-cd-and-automation
description: Add or repair CI lint/build/test/browser checks for the repository's current JavaScript/TypeScript packages. Use for requested workflow automation, CI failures or build/test pipeline changes.
---

# CI and Automation

Read existing workflows, workspace/package scripts, lockfiles, runtime engines and test prerequisites. Preserve the selected provider, package manager and deployment permissions. Discover monorepo versus separate packages and choose supported runtime versions from installed tooling.

Install from authoritative lockfiles and run the actual lint/type-check/build/test scripts in their owning directories. Browser jobs need the project's browser binaries and applicable database/service prerequisites; configure isolated fixtures and mock external delivery. Do not assume client/server directories, MongoDB binary versions, test commands or ports.

Cache by OS/runtime/lockfile and avoid credentials or fixture database state. Bound job/test parallelism for runner capacity using supported controls. Keep deterministic setup/teardown and publish only permitted test artifacts without secrets or real user data.

Limit workflow token permissions and follow existing action/version conventions. Separate automated checks from deployment; a test-only request does not authorize automatic production promotion or live migrations. Apply the established release contract when deployment is in scope.

Validate YAML/configuration, package working directories and equivalent local commands. A local configuration pass does not establish a remote CI pass. Report actual run evidence and any unresolved runner/network/service prerequisites.
