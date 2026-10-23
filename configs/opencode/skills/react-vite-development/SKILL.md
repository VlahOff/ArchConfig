---
name: react-vite-development
description: Build React/Vite screens, hooks, Redux state, shared services and responsive styling using the current repository conventions. Use for React/Vite client feature or UI changes.
---

# React and Vite Development

## Discover the project

Read current repository instructions, owning manifest/lockfile, Vite and lint configuration, entry points, routes, affected components and callers. Identify JavaScript versus TypeScript, JSX/TSX, package boundaries, React/Router versions, state management and styling. Reuse what is installed; do not prescribe a language, component library or directory layout.

## Implement

- Compose existing shared/domain components after checking supported props, variants and callers. Extend compatibly only for a real gap.
- Keep hooks unconditional, dependencies accurate and effects scoped. Clean up subscriptions, timers, observers and async work; prevent stale results after identity or route changes.
- With Redux Toolkit, follow existing slice/thunk/query conventions. Keep shared domain state in the established store and temporary dialog/form state local. Do not duplicate canonical data or persist credentials.
- Put application requests in the established HTTP service/client layer. Preserve its credentials, CSRF, refresh coordination, cancellation, bounded retry and error contract; verify methods and download support before extending it.
- Follow existing CSS Modules, theme tokens or other styling conventions. Handle loading, empty, error, success, pending and permission states, keyboard focus and duplicate submissions.
- Reuse existing workers for expensive calculations; preserve units, domain algorithms, cancellation and message contracts during visual changes.

## Verify

Run the owning package's configured formatter, lint/build and relevant tests from the correct directory. Discover scripts; do not invent a root/client test command. Inspect actual desktop/mobile browser output for visible changes, using `multilingual-browser-qa` when languages are affected. A Vite build alone does not verify layout or session behavior.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
