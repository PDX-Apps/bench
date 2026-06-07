---
description: Generate Vue route page components (*Page.vue) for a Vue 3 frontend. Use whenever the user mentions a page, route view, screen, or top-level UI for a route in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-page** skill. Translate the user's page request into an enriched delegation to the `vue-page` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, Auth, etc.)
- **Page name** — `*Page.vue` suffix
- **Page type**: list | detail | create | settings | dashboard
- **Data needs**: which service, which model
- **Route**: does it exist or needs creating?

## Step 2: Inspect

```bash
ls src/modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls src/modules/{Module}/pages/ 2>/dev/null
ls src/modules/{Module}/services/ 2>/dev/null
ls src/modules/{Module}/router/ 2>/dev/null
ls src/modules/{Module}/i18n/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Module missing → flag that the `{Module}` module needs to exist first
- Service missing → flag: "Page calls `BillService.list()` — service doesn't exist. Generate `/vue-service` first?"
- Route already exists → confirm: update or create new?
- Layout choice → discover from project convention

## Step 4: Build Context Blob

```
Context for vue-page agent:
- Module: {Module}
- Page name: {Name}Page.vue
- Path: src/modules/{Module}/pages/{Name}Page.vue
- Page type: list | detail | create | settings
- Layout: (discover from project)
- Service: {Name}Service
- Service methods: [list, get, create]
- Models rendered: [Bill]
- Components used: [BillCard, BillFormDialog]
- States to handle: loading + empty + error + data (mandatory)
- i18n namespace: {module}; new keys under {module}.pages.{section}.*
- Route binding: {Module}Routes.{LIST|DETAIL|CREATE}
- Existing siblings: [BillsPage.vue, BillPage.vue]
```

## Step 5: Delegate

Task tool, `subagent_type: "vue-page"`, pass the blob.

## Step 6: Synthesize

> "Created `src/modules/Bill/pages/BillsPage.vue`. Calls `BillService.list()` with reactive loading state. Renders `BillCard` grid. Loading/empty/error states handled. New i18n keys under `bill.pages.list.*`. Bound to `BillRoutes.LIST`."

## When to Ask vs Assume

- Loading/empty/error states → always all four
- i18n in all configured locales → always (discover from project)
- Layout / auth meta → follow project convention
