---
description: Verify a ticket's acceptance criteria in a LIVE browser (Chrome MCP or Playwright MCP) and report pass/fail per criterion with evidence — no test file written. Use on "/e2e-run", "verify this ticket works in the browser", "click through the checkout flow and tell me if it meets the acceptance criteria", "drive the browser and check this journey". For WRITING Playwright .spec files, use playwright's /playwright instead.
argument-hint: [ticket / flow to verify + the URL or route to start from]
---

You're the **/e2e-run** skill. Turn the request into a delegation to the `e2e-runner` agent, which drives a live browser to verify the flow's **acceptance criteria** and reports pass/fail with evidence. You don't write files, and neither does the agent — this is live verification, not test authoring.

The user's request: **$ARGUMENTS**

> Writing a reusable Playwright `.spec` file is a different job — that's playwright's `/playwright`. This skill *exercises* a flow live against its acceptance criteria and reports.

## Step 1: Parse
- The **ticket / flow** to verify, its **acceptance criteria** (what "done" means — from the ticket, or ask the user to state them), the **starting URL/route**, and any **inputs** (credentials, search terms).

## Step 2: Resolve
- Confirm a start URL. If only a route is given, ask for or infer the base URL (e.g. the local dev server).
- The agent reads `.bench/e2e.yaml` for the driver (Chrome vs Playwright MCP), pre/post steps, and capture settings (screenshots / network / GIF). Make sure the configured browser MCP is connected.

## Step 3: Build context blob
```
- Ticket/flow: {name}
- Acceptance criteria: {the criteria to verify, one per line}
- Start URL: {url}
- Inputs: {credentials / data to type, if any}
```

## Step 4: Delegate
Task tool, `subagent_type: "e2e-runner"`, pass the blob plus `project_root: <cwd>`.

## Step 5: Synthesize
Relay the verification report: **pass/fail per acceptance criterion** with evidence, each step (observed vs expected), console + network findings, and any captured artifacts (screenshots, GIF). Make clear no test file was saved; if the user wants a durable test, point them at playwright's `/playwright`.
