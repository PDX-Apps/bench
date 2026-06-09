# bench-e2e

**Acceptance-criteria browser verification.** Drives a real browser via an MCP (Chrome MCP or Playwright MCP) to verify a ticket's **acceptance criteria** — walking the flow and reporting **pass/fail per criterion** with evidence: observed vs expected, screenshots, console errors, network failures, and an optional GIF of the run. **No test file is written.**

For "verify this ticket works in the browser" — live verification against what "done" means, not a saved test.

## bench-e2e vs playwright

|              | **bench-e2e** (this addon)                                                     | **playwright**                           |
|--------------|--------------------------------------------------------------------------------|------------------------------------------------|
| What it does | *Verifies* a ticket's acceptance criteria in a live browser, right now         | *Writes* a reusable `.spec` test file          |
| Output       | A verification report (pass/fail per criterion, screenshots, console, network) | Playwright spec(s) + page objects + auth setup |
| Persists?    | No code saved (screenshots/GIF are evidence)                                   | Yes — committed test files                     |
| Driven by    | Chrome MCP or Playwright MCP (live)                                            | Playwright test runner                         |
| Use when     | "Does this ticket meet its acceptance criteria?"                               | "Give me a regression test for this flow"      |

If you verify a flow with bench-e2e and want it to stick as a regression test, hand the same flow to playwright's `/playwright`.

## What it ships
- **`/e2e-run`** skill → **`e2e-runner`** agent — drives a live browser through a flow and reports pass/fail per acceptance criterion with evidence.
- **E2E-001** pattern — conventions for an acceptance-criteria run-through (derive steps from the criteria, before/after frames, screenshots, console + network checks, avoid native dialogs, pass/fail reporting).
- **`e2e` concern** — at setup, captures the **driver** (Chrome vs Playwright MCP), your **pre/post steps** (default: read the acceptance criteria → report pass/fail per criterion), and **capture settings** (screenshots, network inspection, GIF) into `.bench/e2e.yaml`.

## Configuration — `.bench/e2e.yaml`
The `e2e` concern writes it; the agent reads it and never re-asks:
```yaml
driver: chrome          # chrome (claude-in-chrome MCP) | playwright (Playwright MCP)
pre_steps:              # default reads the ticket's acceptance criteria
  - read the ticket's acceptance criteria and derive the steps + expected outcomes
post_steps:
  - report pass/fail against each acceptance criterion
screenshots: true       # screenshot at each meaningful step
network: true           # flag failed / 4xx / 5xx requests
gif: true               # record a GIF of the run
```
Advanced capture (network + GIF) defaults on — turn it off if it slows runs too much.

## Requires
A **browser MCP connected** — Chrome MCP (claude-in-chrome) for the `chrome` driver, or the Playwright MCP for the `playwright` driver. Without it, the run can't proceed.

## Install
```bash
bench addon add bench-e2e && bench rebuild
```
