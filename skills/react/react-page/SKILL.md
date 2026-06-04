---
description: Generate React route page components (*Page.tsx) for a React frontend. Use whenever the user mentions a page, route view, screen, or top-level UI for a route in the React project.
argument-hint: [what the user needs]
---

You're the **/react-page** skill. Translate the user's page request into an enriched delegation to the `react-page` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module**
- **Page name** — `*Page.tsx` suffix
- **Page type**: list | detail | create | settings | dashboard
- **Data needs**: which service, which model
- **Route**: exists or needs creating?

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/pages/ 2>/dev/null
ls src/modules/{Module}/services/ 2>/dev/null
ls src/modules/{Module}/router/ 2>/dev/null
ls src/modules/{Module}/i18n/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module missing → suggest `/react-new-module {Module}`
- Service missing → flag: "Generate `/react-service` first?"
- Route exists → confirm: update or new?
- Layout choice → discover from project convention

## Step 4: Build Context Blob

```
Context for react-page agent:
- Module: {Module}
- Page name: {Name}Page.tsx
- Path: src/modules/{Module}/pages/{Name}Page.tsx
- Page type: list | detail | create | settings
- Layout: (discover from project — AppLayout, GuestLayout, etc.)
- Service: {Name}Service
- Service methods: [list, get, create]
- Models rendered: [Bill]
- Components used: [BillCard, BillFormDialog]
- States: loading + empty + error + data (mandatory)
- i18n namespace: {module}; new keys under {module}.pages.{section}.*
- Route binding: {Module}Routes.{LIST|DETAIL|CREATE}
- Async pattern: TanStack Query (or project equivalent)
- Existing siblings: [BillsPage.tsx]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:react-page"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Bill/pages/BillsPage.tsx`. Uses `useQuery` for `BillService.list()`. Renders `BillCard` grid. Loading/empty/error states handled. Default export for lazy loading."

## When to Ask vs Assume

- **Default export** (for lazy loading) → always
- Loading/empty/error states → always all four
- i18n in all configured locales → always (discover)
- Layout/auth meta → follow project convention
