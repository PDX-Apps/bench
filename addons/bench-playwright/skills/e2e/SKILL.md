---
description: Generate Playwright end-to-end tests for a user flow (auth, CRUD journey, critical path) across a real browser. Use when the user wants an e2e test, a flow/journey test, or browser automation tests.
argument-hint: [the user flow to test]
---

You're the **/e2e** skill. Turn the flow into an enriched delegation to the `e2e` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The flow (steps a user takes); the route(s) involved; auth required?
## Step 2: Resolve
- Detect framework (vue/react) + whether Playwright is set up (`playwright.config.ts`, `e2e/`). If not set up, the agent scaffolds config + auth setup.
## Step 3: Build context blob
```
- Flow: {steps}
- Routes: {paths}
- Auth: {required? which role}
- Playwright set up: {yes/no}
```
## Step 4: Delegate
Task tool, `subagent_type: "e2e"`, pass the blob.
## Step 5: Synthesize
Report the spec (+ any page object / config) and how to run (`npx playwright test`).
