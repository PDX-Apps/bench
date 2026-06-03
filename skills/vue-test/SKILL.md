---
description: Generate Vitest component tests or Playwright E2E tests for a Vue 3 frontend. Use whenever the user mentions frontend tests, Vitest, Playwright, component testing, E2E testing, or test coverage in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-test** skill. Translate the user's frontend test request into an enriched delegation to the `vue-test` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Test type**: `component` (Vitest, isolated) OR `e2e` (Playwright, full browser)
- **Subject**: which component/page/flow is being tested
- **Module**: where the subject lives
- **Cases**: rendering, user interaction, async/loading, error states, navigation flows

## Step 2: Inspect

```bash
ls tests/unit/ 2>/dev/null || ls src/**/__tests__/ 2>/dev/null
ls tests/e2e/ 2>/dev/null
ls src/modules/{Module}/components/ 2>/dev/null
cat vitest.config.ts 2>/dev/null | head -30
ls tests/setup* 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Type unclear → ask: "Component test (Vitest) or E2E (Playwright)?"
- E2E auth → assume `beforeEach` login flow unless test is for auth itself
- Subject missing → flag: "Component doesn't exist. Generate via `/vue-component` first?"

## Step 4: Build Context Blob

```
Context for vue-test agent:
- Type: component | e2e
- Subject: {ComponentName} | {flow-name}
- Test file path:
    component: tests/unit/{Component}.spec.ts
    e2e:       tests/e2e/{flow}.spec.ts
- Component import path: src/modules/{Module}/components/{Folder}/{Name}.vue
- Required setup (component):
    - Pinia reset in beforeEach
    - Mock any services the component imports
    - UI library plugin if project uses one (discover)
- Mocks needed: [BillService.list → resolves [Bill...]]
- Cases to cover:
    component: [renders props, emits on click, loading state, error state]
    e2e: [happy path, validation failure, unauthorized]
- Existing siblings: [BillCard.spec.ts]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:vue-test"`, pass the blob.

## Step 6: Synthesize

> "Created `tests/unit/BillCard.spec.ts` with 4 component tests. Pinia reset in `beforeEach`, services mocked."

## When to Ask vs Assume

- Vitest + @vue/test-utils → always for component tests
- Playwright → always for E2E
- `data-testid` selectors → always
- Pinia reset in `beforeEach` → always
- UI library plugin → discover from existing tests, don't assume Quasar
