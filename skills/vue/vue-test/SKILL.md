---
description: Generate Vitest unit/component tests (@vue/test-utils, data-testid selectors, emitted-event assertions). Use when the user wants to test a component, composable, store, or add unit tests. (End-to-end → bench-playwright addon.)
argument-hint: [what to test]
---

You're the **/vue-test** skill. Enrich and delegate to the `vue-test` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The unit under test (component/composable/store) + its path
- Key behaviors to cover (render, emits, interactions, edge cases)

## Step 2: Resolve
- Detect test location convention (co-located `*.spec.ts` vs `tests/`) — match.
- If the unit uses queries, note the QueryClient/mock setup needed.

## Step 3: Build context blob
```
- Under test: {path}
- Behaviors: {list}
- Mocks: {HTTP boundary / query client}
- Location: {co-located | tests/}
```

## Step 4: Delegate
Task tool, `subagent_type: "vue-test"`, pass the blob.

## Step 5: Synthesize
Report the test file + cases; note it runs with `vitest`.
