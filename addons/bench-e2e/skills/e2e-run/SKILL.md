---
description: Exercise a user flow in a LIVE browser via the Chrome MCP and report whether it works — no test file written. Use on "/e2e-run", "click through the checkout flow and tell me if it works", "drive the browser and verify this journey", "exploratory run-through". For WRITING Playwright .spec files, use bench-playwright's /e2e instead.
argument-hint: [flow to exercise + the URL/route to start from]
---

You're the **/e2e-run** skill. Turn the request into a delegation to the `e2e-runner` agent, which drives a live browser and reports what happened. You don't write files, and neither does the agent — this is exploratory verification, not test authoring.

The user's request: **$ARGUMENTS**

> Writing a reusable Playwright `.spec` file is a different job — that's bench-playwright's `/e2e`. This skill only *exercises* a flow live and reports.

## Step 1: Parse
- The flow (the steps a user takes), the starting URL/route, any inputs (credentials, search terms), and the expected outcome ("lands on the receipt page").

## Step 2: Resolve
- Confirm a start URL. If only a route is given, ask for or infer the base URL (e.g. the local dev server). The agent needs the Chrome MCP connected to drive the browser.

## Step 3: Build context blob
```
- Flow: {ordered steps}
- Start URL: {url}
- Inputs: {credentials / data to type, if any}
- Expected outcome: {what success looks like}
```

## Step 4: Delegate
Task tool, `subagent_type: "e2e-runner"`, pass the blob.

## Step 5: Synthesize
Relay the run report: each step (observed vs expected), any failures, and console errors. Make clear nothing was saved to disk; if the user wants a durable test, point them at bench-playwright's `/e2e`.
