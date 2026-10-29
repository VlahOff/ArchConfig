---
name: multilingual-browser-qa
description: Verify UI workflows, translations, responsive layouts, themes and keyboard behavior across the repository's supported locales. Use for multilingual features or browser/layout QA; English/Bulgarian are examples, not requirements.
---

# Multilingual Browser QA

Discover the actual locale mechanism, supported languages, theme modes, browser suites and test harness. Reuse installed localization libraries and existing selectors; do not invent i18next, locale URL parameters or two-language support. Determine affected workflows and explicit expected outcomes before testing.

Build a coverage matrix of supported/affected locales x existing themes x desktop/mobile viewports. English/Bulgarian, light/dark and 1440x900/360px are example cells only; use the user's requirements and current project breakpoints. If only one locale/theme exists, test it and do not add another. Include RTL layout when a supported locale requires it. For a large matrix, agree a practical affected/risk-based scope and report omitted cells.

Use available browser MCP tools for interactive inspection and the current Playwright or other browser suite for repeatable coverage. Use synthetic accounts, disposable data and mocked external delivery. Existing terminal browser tests can run without an MCP if dependencies/binaries are present; an MCP config does not install all test-runner prerequisites.

For each relevant cell inspect actual screenshots and DOM/keyboard behavior: labels, headings, validation, errors, loading/empty/pending states, text expansion, glyph/font coverage, wrapping/clipping/overflow, contrast, focus containment/restoration and date/number formatting. Confirm expected language persistence and fallback behavior rather than changing it implicitly. Verify downloaded documents/text when the workflow produces them.

Exercise success, failure, cancellation and duplicate submission; preserve input after recoverable failure. Test relevant current roles/resource scope and session transitions. Distinguish expected negative-test network responses from defects, but record unexpected console/page errors.

Run the repository's actual affected browser command. Reduce worker/test concurrency on constrained machines using options supported by its installed runner; do not assume a specific Node glob. Report per-cell pass/fail/not-run, flow/actor, screenshots inspected and missing evidence. Never infer a visual pass from lint/build or DOM text alone.
