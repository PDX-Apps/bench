---
description: Generate Playwright end-to-end tests for a user flow (auth, CRUD journey, critical path) across a real browser. Use on "/playwright", or when the user wants an e2e test, a flow/journey test, a Playwright spec, or browser automation tests.
argument-hint: [the user flow to test]
---

You're the **/playwright** skill. Turn the flow into an enriched delegation to the `playwright` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The flow (steps a user takes); the route(s) involved; auth required?
## Step 2: Resolve
- Detect framework (vue/react) + whether Playwright is set up (`playwright.config.ts`). If not set up, the agent scaffolds config + auth setup. The agent reads `testDir` from the config for where specs live.
## Step 3: Build context blob
```
- Flow: {steps}
- Routes: {paths}
- Auth: {required? which role}
- Playwright set up: {yes/no}
```
## Step 4: Delegate
Task tool, `subagent_type: "playwright"`, pass the blob.
## Step 5: Synthesize
Report the spec (+ any page object / config) and how to run (`npx playwright test`).

## Not covered by a pattern?

If the request needs a **playwright** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "playwright" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
