---
name: frontend-ui-engineering
description: Build or revise accessible responsive UI using the existing component and design system. Use for visible pages, forms, dialogs and interactions.
---

# Frontend UI Engineering

1. Read the relevant components, styles, callers and visual requirements. Reuse shared primitives and supported props/variants before custom markup; extend compatibly only for a demonstrated gap.
2. Use project theme/spacing/type tokens and CSS conventions. For React/Vite use `react-vite-development` and the existing styling/state/service conventions; do not introduce a new UI framework, component library or language migration incidentally.
3. Model loading, empty, success, error, pending and forbidden states. Preserve entered data after recoverable errors, prevent duplicate submits and make async cleanup session-aware.
4. Keep labels, semantic buttons, keyboard access, visible focus, dialog focus containment/restoration and meaningful accessible names. Verify actual components rather than adding unsupported ARIA props.
5. Design at real mobile and desktop widths; allow long names and Bulgarian/Cyrillic strings. Check both existing themes. Preserve calculations, units, sorting and ownership when changing presentation.
6. Run required formatting/lint/build plus relevant browser flows. Inspect rendered output for overlap/clipping; static checks cannot prove layout. Use `multilingual-browser-qa` for multilingual changes.

Report visible behavior and evidence. Avoid aesthetic rewrites unrelated to the request.

## Execution rules

- Follow the user's task and current repository instructions first. Discover applicable `AGENTS.md`, style guides, architecture docs, protected files and package scripts; respect their exclusions throughout reads, searches, formatting, diffs and staging.
- Complete work in the main agent by default. Loading a skill does not mean spawning an agent. Delegate only a necessary, bounded task; allow at most one active subagent, wait for completion, use the same configured local model, and never delegate recursively from a subagent.
- Keep scope small and reuse the installed stack. Load only relevant skills/resources. Do not require a full lifecycle, repeated review agents, or approval checkpoints for routine authorized work.
- Discover actual source paths, module conventions, authentication and data ownership. Do not import another project's roles, business rules, endpoint exceptions, test commands or directory layout.
- Use actual repository commands and available tools. Report checks and limitations honestly; never claim browser verification from static checks alone.
