---
concern: e2e
title: Browser verification (driver + capture)
order: 55
when: always
questions:
  - id: driver
    ask: "Which browser MCP drives the run — Chrome MCP (claude-in-chrome) or Playwright MCP?"
    options: [chrome, playwright]
    default: chrome
  - id: pre_steps
    ask: "Steps to run BEFORE driving a flow (one per line). Default reads the ticket's acceptance criteria and derives the steps + expected outcomes. Add project-specific setup (seed a user, set a feature flag, pick an environment)."
    default: "read the ticket's acceptance criteria and derive the steps + expected outcomes"
  - id: post_steps
    ask: "Steps to run AFTER the flow (one per line) — how you want results curated. Default reports pass/fail per acceptance criterion."
    default: "report pass/fail against each acceptance criterion"
  - id: screenshots
    ask: "Capture a screenshot at each meaningful step? (enterprise default: yes)"
    options: [yes, no]
    default: yes
  - id: advanced
    ask: "Enable advanced capture — network-request inspection (flag failed/4xx/5xx calls) and a GIF recording of the run? On by default; turn off if it slows runs too much."
    options: [yes, no]
    default: yes
output: config:.bench/e2e.yaml
---

## Apply

Write `.bench/e2e.yaml` — how this project runs a browser verification, read by the `e2e-runner` agent:

```yaml
# .bench/e2e.yaml — read by the e2e-runner agent
driver: {driver}          # chrome (claude-in-chrome MCP) | playwright (Playwright MCP)

pre_steps:                # run before driving the flow (each line → one item)
  - {pre_steps line 1}
  - {pre_steps line 2}

post_steps:               # run after the flow, to curate the result
  - {post_steps line 1}

screenshots: {true|false} # capture a screenshot at each meaningful step
network: {true|false}     # inspect network requests; flag failed / 4xx / 5xx
gif: {true|false}         # record a GIF of the whole run
```

Rules for assembling it:

- **`driver`** — the chosen MCP. `chrome` → the `mcp__claude-in-chrome__*` tools; `playwright` → the Playwright MCP's browser tools.
- **`pre_steps` / `post_steps`** — split the user's answer into one list item per line; keep the default item if they only added to it. These are the user's pre/post ritual the agent runs around the flow.
- **`screenshots`** — `yes` → `true`, `no` → `false`.
- **`network` and `gif`** — both follow the single `advanced` answer (`yes` → both `true`, `no` → both `false`).

Write only these keys. The agent reads them and never re-asks at run time.
