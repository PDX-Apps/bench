---
description: Generate Vitest component tests or Playwright E2E tests for a React frontend. Use whenever the user mentions React tests, Vitest, Playwright, component testing, E2E testing, or test coverage in the React project.
argument-hint: [what the user needs]
---

You're the **/react-test** skill. Translate the user's React test request into an enriched delegation to the `react-test` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Test type**: `component` (Vitest + @testing-library/react) OR `e2e` (Playwright)
- **Subject**: which component/page/flow
- **Module**: where the subject lives
- **Cases**: rendering, user interaction, async/loading, error states, navigation

## Step 2: Inspect

```bash
ls tests/unit/ 2>/dev/null || ls src/**/__tests__/ 2>/dev/null
ls tests/e2e/ 2>/dev/null
ls src/modules/{Module}/components/ 2>/dev/null
cat vitest.config.ts 2>/dev/null | head -30
ls tests/setup* 2>/dev/null
ls tests/e2e/page-objects/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Type unclear → ask: "Component test (Vitest) or E2E (Playwright)?"
- E2E auth → assume `beforeEach` login flow
- Subject missing → flag: "Component doesn't exist. Generate via `/react-component` first?"

## Step 4: Build Context Blob

```
Context for react-test agent:
- Type: component | e2e
- Subject: {ComponentName} | {flow-name}
- Test file path:
    component: tests/unit/{Component}.spec.tsx
    e2e:       tests/e2e/{flow}.spec.ts
- Component import path: src/modules/{Module}/components/{Folder}/{Name}.tsx
- Required setup (component):
    - QueryClientProvider with fresh QueryClient (retry: false)
    - MemoryRouter if component uses router hooks
    - Reset Zustand stores in beforeEach if relevant
    - Mock services
- Mocks needed: [BillService.list mocked]
- Cases:
    component: [renders props, calls callback on click, loading/error states]
    e2e: [happy path, validation failure, unauthorized]
- Page Object: tests/e2e/page-objects/{Name}.ts (if E2E and new flow)
- Existing siblings: [BillCard.spec.tsx]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-test"`, pass the blob.

## Step 6: Synthesize

> "Created `tests/unit/BillCard.spec.tsx` with 4 component tests. Services mocked, QueryClient provider wrapped. Tests pass."

## When to Ask vs Assume

- Vitest + @testing-library/react + user-event → always for component
- Playwright + Page Objects → always for E2E
- `getByRole` first, `getByTestId` as fallback → always
- `userEvent` not `fireEvent` → always
