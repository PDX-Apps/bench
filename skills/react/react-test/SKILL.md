---
description: Generate Vitest + Testing Library tests (render, getByRole, userEvent, callback assertions). Use when the user wants to test a component, hook, or store, or add unit tests. (End-to-end → playwright addon.)
argument-hint: [what to test]
---

You're the **/react-test** skill. Enrich and delegate to the `react-test` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The unit under test (component/hook/store) + path; behaviors to cover
## Step 2: Resolve
- Detect test location (co-located `*.test.tsx` vs `tests/`); note QueryClient wrap if it uses queries.
## Step 3: Build context blob
```
- Under test: {path}
- Behaviors: {list}
- Mocks: {HTTP boundary / query client}
```
## Step 4: Delegate
Task tool, `subagent_type: "react-test"`, pass the blob.
## Step 5: Synthesize
Report the test file + cases; runs with `vitest`.
