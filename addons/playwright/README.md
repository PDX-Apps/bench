# playwright

End-to-end testing with **Playwright** — user-flow tests across real browsers. The base ships Vitest unit/component tests; this adds the e2e layer.

## What it ships
- **`/playwright`** skill + **`playwright`** agent — generate flow specs, page objects, and auth setup; scaffold `playwright.config.ts` if needed; infers the test dir from the config.
- **TEST-002-e2e** pattern (Vue + React) — flows, role-based locators, page objects, `storageState` auth, plus an opt-in advanced layer (trace-on-failure, cross-browser projects, fixtures, visual snapshots).

## Naming
This addon **writes durable Playwright `.spec` files**. For *live* verification of a ticket's acceptance criteria via a browser MCP (no file written), that's the separate **`bench-e2e`** addon (`/e2e-run`).

## Install
```bash
npm init playwright@latest          # one-time: installs Playwright + browsers
bench addon add playwright && bench rebuild
```
