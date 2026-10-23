---
name: idea-refine
description: Clarify a vague product idea, compare a few feasible directions and define a small testable scope. Use when the user asks to refine an idea before implementation.
---

# Idea Refine

Restate the target person, problem and success criterion. Use known context first; ask only consequential missing questions using the available question interface or plain text. Do not assume Claude-specific tools such as AskUserQuestion, Glob or Read exist.

Explore a few meaningfully different approaches, then compare user value, implementation cost and assumptions. Ground options in the existing stack and constraints. Recommend a minimal scope with explicit acceptance criteria, exclusions and a way to test the riskiest assumption. Avoid expanding a focused idea into a new platform.

Use [frameworks.md](frameworks.md), [refinement-criteria.md](refinement-criteria.md) and [examples.md](examples.md) only when deeper exploration helps. The optional `scripts/idea-refine.sh` creates `docs/ideas`; run it only for an authorized file-creation task from the project root.

Deliver a concise direction and open decisions. Save a one-page note at `docs/ideas/<idea>.md` when the user requested a file or the current work needs it, preserving existing notes. An idea discussion does not automatically authorize implementation, agents or deployment.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
