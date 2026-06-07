# bench-playwright

End-to-end testing with **Playwright** — user-flow tests across real browsers. The base ships Vitest unit/component tests; this adds the e2e layer.

## What it ships
- **`/e2e`** skill + **`e2e`** agent — generate flow specs, page objects, and auth setup; scaffold `playwright.config.ts` if needed.
- **TEST-002-e2e** pattern (Vue + React) — flows, role-based locators, page objects, `storageState` auth.

## Install
```bash
npm init playwright@latest
bench addon add /path/to/bench/addons/bench-playwright && bench rebuild
```
