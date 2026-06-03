---
description: Generate Vue Router route definitions and route name constants for a Vue 3 frontend. Use whenever the user mentions a route, navigation, URL path, route guard, or routes.ts/constants.ts in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-route** skill. Translate the user's route request into an enriched delegation to the `vue-route` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, Auth, etc.)
- **URL path** (`/bills`, `/bills/:id`)
- **Route name(s)** (`{Module}Routes.LIST`, `.DETAIL`, `.CREATE`)
- **Component**: which `*Page.vue` does this route bind to
- **Auth state**: protected, guest-only, or public
- **Layout** the parent route uses

## Step 2: Inspect

```bash
ls src/modules/{Module}/router/ 2>/dev/null || echo "MODULE_MISSING_OR_NO_ROUTER"
ls src/modules/{Module}/pages/ 2>/dev/null
ls src/router/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Page missing → flag: "Route binds to `BillPage.vue` — doesn't exist. Generate `/vue-page` first?"
- Auth state unclear → assume protected
- Param patterns → discover project convention (UUID? ULID? numeric?)

## Step 4: Build Context Blob

```
Context for vue-route agent:
- Module: {Module}
- URL path: /bills | /bills/:id
- Route names: [{Module}Routes.LIST, {Module}Routes.DETAIL]
- Page bindings: [BillsPage.vue (LIST), BillPage.vue (DETAIL)]
- Auth meta: { requiresAuth: true }  (match project convention)
- Layout: AppLayout (if project uses layout routes)
- Meta: { title: '...', breadcrumb: { label: '{module}.breadcrumb.list', icon: 'list' } }
- Existing routes: [...]
- Existing constants: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:vue-route"`, pass the blob.

## Step 6: Synthesize

> "Added 2 routes to `src/modules/Bill/router/routes.ts`: `BillRoutes.LIST` → `BillsPage`, `BillRoutes.DETAIL` → `BillPage`. Constants enum updated."

## When to Ask vs Assume

- Lazy import → always
- Auth meta / layout → follow project convention (discover from existing routes)
- Param patterns → match project
