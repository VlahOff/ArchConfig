---
name: idea-refine
description: Clarify a vague product idea, compare a few feasible directions and define a small testable scope. Use when the user asks to refine an idea before implementation.
---

# Idea Refine

Restate the target person, problem and success criterion. Use known context first; ask only consequential missing questions using the available question interface or plain text. Do not assume Claude-specific tools such as AskUserQuestion, Glob or Read exist.

Explore a few meaningfully different approaches, then compare user value, implementation cost and assumptions. Ground options in the existing stack and constraints. Recommend a minimal scope with explicit acceptance criteria, exclusions and a way to test the riskiest assumption. Avoid expanding a focused idea into a new platform.

Use [frameworks.md](frameworks.md), [refinement-criteria.md](refinement-criteria.md) and [examples.md](examples.md) only when deeper exploration helps. The optional [scripts/idea-refine.sh](scripts/idea-refine.sh) creates `docs/ideas` relative to the working directory. Resolve the helper's absolute path from this skill's directory and invoke it from the project root, only when file creation is authorized.

Deliver a concise direction and open decisions. Save a one-page note at `docs/ideas/<idea>.md` when the user requested a file or the current work needs it, preserving existing notes. An idea discussion does not automatically authorize implementation, agents or deployment.
