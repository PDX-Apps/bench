# bench-e2e

**Live browser click-through verification.** Drives a real Chrome via the Chrome MCP to *exercise* a user flow and report whether it works — steps taken, observed vs expected, failures, and console errors. **No file is written.**

For "click through the checkout flow and tell me if it works" — exploratory verification, not a saved test.

## bench-e2e vs bench-playwright

| | **bench-e2e** (this addon) | **bench-playwright** |
|---|---|---|
| What it does | *Exercises* a flow in a live browser, right now | *Writes* a reusable `.spec` test file |
| Output | A run report (observed vs expected, console errors) | Playwright spec(s) + page objects + auth setup |
| Persists? | No — nothing saved to disk | Yes — committed test files |
| Driven by | Chrome MCP (`mcp__claude-in-chrome__*`) live tools | Playwright test runner |
| Use when | "Does this flow work right now?" | "Give me a regression test for this flow" |

If you exercise a flow with bench-e2e and want it to stick as a regression test, hand the same flow to bench-playwright's `/e2e`.

## What it ships
- **`/e2e-run`** skill → **`e2e-runner`** agent — navigates a live browser through a flow and reports.
- **E2E-001** pattern — conventions for a live MCP run-through (before/after frames, console checks, avoid native dialogs, observed vs expected reporting).

## Requires
The **Chrome MCP (claude-in-chrome) must be connected** — the agent drives the browser through it. Without it, the run can't proceed.

## Install
```bash
bench addon add /path/to/bench/addons/bench-e2e && bench rebuild
```
