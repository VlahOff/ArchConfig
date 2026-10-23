# OpenCode browser setup

Skills provide instructions; the browser tool must be configured separately. Use one browser MCP, not two by default. Verified against official OpenCode and Playwright docs on 2026-10-12; recheck options if versions change.

For the user's Arch Linux system, an optional Playwright MCP configuration merge is supplied at pack-root setup/opencode-playwright.merge.json. It uses npx, an isolated headless profile and /usr/bin/chromium. Check that executable exists. Merge mcp.playwright into the existing OpenCode config, preserving providers, models, permissions, agents, SearXNG and all other keys. Do not overwrite the whole config. Restart OpenCode and use `opencode mcp list` plus a real localhost navigation to verify connection.

The sample uses @latest for initial setup; after a successful setup record and optionally pin the tested package version for reproducibility. npx needs Node/npm and network access on first launch. Removing --headless opens a browser window; it is not needed for screenshots. If Chromium is elsewhere, replace the executable path with the observed path. Do not disable the sandbox as a generic remedy.

This system-browser MCP does not install the browser binary needed by a project's Playwright test runner. From the package owning its installed Playwright dependency use `npx playwright install chromium` for those tests, after installing dependencies from the existing lockfile. Read the repository test prerequisites, including any isolated database/service requirements.

For an already working Chrome DevTools MCP keep that server and use its advertised tools; do not install Playwright MCP merely because this pack mentions it. If neither MCP is available, existing terminal browser tests can still run when prerequisites exist. State missing interactive/visual inspection accurately.

Official sources:
- https://docs.opencode.ai/docs/mcp-servers/
- https://playwright.dev/mcp/configuration/options
- https://github.com/microsoft/playwright-mcp
