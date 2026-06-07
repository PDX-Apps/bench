---
description: Generate React Router route definitions and route id constants for a React frontend. Use whenever the user mentions a route, navigation, URL path, route guard, or routes.ts/constants.ts in the React project.
argument-hint: [what the user needs]
---

You're the **/react-route** skill. Translate the user's route request into an enriched delegation to the `react-route` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module**
- **URL path** (`/bills`, `/bills/:id`)
- **Route ids** (`{Module}Routes.LIST`, `.DETAIL`, `.CREATE`)
- **Component**: which `*Page.tsx`?
- **Auth state**: protected, guest-only, or public
- **Layout** the parent route uses

## Step 2: Inspect

```bash
ls src/modules/{Module}/router/ 2>/dev/null || echo "MODULE_MISSING_OR_NO_ROUTER"
ls src/modules/{Module}/pages/ 2>/dev/null
ls src/router/ 2>/dev/null   # project-wide router config
```

## Step 3: Resolve Ambiguity

- Page missing → flag: "Route would bind to `BillPage.tsx` — generate `/react-page` first?"
- Auth state unclear → assume protected
- Auth mechanism → discover from project (loader-based, handle-meta + global guard, or wrapper component)

## Step 4: Build Context Blob

```
Context for react-route agent:
- Module: {Module}
- URL path: /bills | /bills/:id
- Route ids: [{Module}Routes.LIST, {Module}Routes.DETAIL]
- Page bindings: [BillsPage.tsx (LIST), BillPage.tsx (DETAIL)]
- Auth convention: loader-based / handle-meta / wrapper (discover)
- Layout: AppLayout (parent route element with <Outlet />)
- Handle meta: { title, breadcrumb }
- Existing routes: [...]
- Existing constants: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "react-route"`, pass the blob.

## Step 6: Synthesize

> "Added 2 routes to `src/modules/Bill/router/routes.ts`: `BillRoutes.LIST` → `<BillsPage />`, `BillRoutes.DETAIL` → `<BillPage />`. Constants enum updated."

## When to Ask vs Assume

- Lazy import → always (`lazy(() => import(...))`)
- Auth meta → follow project convention
- Param patterns → match what the project uses
