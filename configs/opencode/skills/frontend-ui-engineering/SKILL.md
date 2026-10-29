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
