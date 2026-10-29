# OpenCode browser setup

Skills provide instructions; the browser tool must be configured separately. Use one browser MCP, not two by default. Discover existing servers before changing configuration; a missing tool does not itself authorize installation or reconfiguration.

For an authorized setup on this Arch Linux system, the following fragment matches the installed OpenCode v2.2.1 `mcp.servers` layout observed on 2026-10-29. Check `opencode --version` and the current configuration before adapting it to another release; OpenCode 1 examples using `mcp.playwright` are not the same layout.

```json
{
  "mcp": {
    "servers": {
      "playwright": {
        "type": "local",
        "command": [
          "npx",
          "-y",
          "@playwright/mcp@latest",
          "--headless",
          "--isolated",
          "--executable-path",
          "/usr/bin/chromium"
        ],
        "disabled": false,
        "codemode": true,
        "timeout": {
          "catalog": 30000,
          "execution": 120000
        }
      }
    }
  }
}
```

Merge only `mcp.servers.playwright` into the existing config, preserving providers, models, permissions, agents, SearXNG and all other keys. Check that `/usr/bin/chromium` exists; replace the executable path when needed. Restart or reload OpenCode when it is safe to do so, then use `opencode mcp list` and a real localhost navigation to verify the connection. Configuration validation alone does not prove browser operation.

`--isolated` keeps browser state in memory and discards it when the browser closes; `--headless` only controls window visibility. Do not assume a default or merely headless profile is isolated. Removing `--headless` opens a window and is not needed for screenshots. Do not disable the sandbox as a generic remedy.

The fragment uses `@latest` for initial setup; after a successful setup record and optionally pin the tested package version for reproducibility. `npx` needs Node/npm and network access on first launch.

This system-browser MCP does not install the browser binary needed by a project's Playwright test runner. From the package owning its installed Playwright dependency use `npx playwright install chromium` for those tests, after installing dependencies from the existing lockfile. Read the repository test prerequisites, including any isolated database/service requirements.

For an already working Chrome DevTools MCP keep that server and use its advertised tools; do not install Playwright MCP merely because this pack mentions it. If neither MCP is available, existing terminal browser tests can still run when prerequisites exist. State missing interactive/visual inspection accurately.

Official sources:
- [OpenCode MCP documentation](https://docs.opencode.ai/docs/mcp-servers/) (check the release-specific layout against the installed CLI/configuration)
- [Playwright MCP configuration](https://playwright.dev/mcp/configuration/options)
- [Playwright MCP profile modes](https://github.com/microsoft/playwright-mcp#user-profile)
