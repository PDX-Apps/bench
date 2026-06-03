# ROUTE-001-route-definitions

## Pattern

Each module declares its routes in `src/modules/{Name}/router/routes.ts`. The project's router setup collects routes from all modules and registers them globally — either via plain imports in `src/router/index.ts` or via a framework wrapper.

## Structure

```typescript
import type { RouteRecordRaw } from 'vue-router';
import { BillRoutes } from './constants';

const ULID_PATTERN = '([0-9A-HJKMNP-TV-Z]{26})';   // example — use project's shared pattern if it has one

const routes: RouteRecordRaw[] = [
  {
    path: '/bills',
    component: () => import('src/layouts/AppLayout.vue'),
    meta: {
      requiresAuth: true,
    },
    children: [
      {
        path: '',
        name: BillRoutes.LIST,
        component: () => import('../pages/BillsPage.vue'),
        meta: {
          title: 'Bills',
          breadcrumb: { label: 'bill.breadcrumb.list', icon: 'list' },
        },
      },
      {
        path: `:id${ULID_PATTERN}`,
        name: BillRoutes.DETAIL,
        component: () => import('../pages/BillPage.vue'),
        meta: {
          title: 'Bill',
          breadcrumb: {
            label: (_route, ctx) => (ctx?.name as string) ?? 'Details',
          },
        },
      },
    ],
  },
];

export default routes;
```

## Auth Meta

How auth is expressed in route meta depends on the project's router guards. Common conventions:

| Convention | Shape |
|------------|-------|
| Boolean flag + global guard | `meta: { requiresAuth: true }` |
| Function-based guard helpers | `meta: { auth: createProtectedAuth() }` |
| Per-route `beforeEnter` | inline guard function |

Discover the convention by reading an existing route file. Don't introduce a new one.

## Layout Wrapping

If the project uses layout routes, the parent route declares the layout component; child routes are the pages:

```
/bills                    ← parent: AppLayout
  /                       ← child: BillsPage (rendered in <router-view />)
  /:id                    ← child: BillPage
```

If the project doesn't use layout routes (each page wraps its own layout), follow that convention.

Use lazy imports (`() => import(...)`) for code-splitting.

## URL Patterns

If the project keeps shared route patterns (e.g., for ULID, UUID, slug formats), import from there rather than re-declaring:

```typescript
import { ULID } from 'src/router/patterns';

path: `:id${ULID}`,  // matches ULID format only
```

This validates the param at the route level; non-matching paths fall through to 404.

## Route Names

Use the module's route enum (see ROUTE-002) — never hardcoded strings:

```typescript
// ✅ Right
name: BillRoutes.LIST

// ❌ Wrong
name: 'bill.list'
```

## Title Meta

```typescript
meta: { title: 'Bill' }
```

Pages or layouts can read `route.meta.title` for `document.title` updates (often handled in App.vue or a global guard).

## Breadcrumb Meta

See LAYOUT-001 for the full breadcrumb pattern. Routes contribute one breadcrumb each via:

```typescript
meta: {
  breadcrumb: { label: 'bill.breadcrumb.list', icon: 'home' },
  // OR dynamic:
  breadcrumb: { label: (route, ctx) => ctx?.name ?? route.params.id },
}
```

## Conventions

- Routes file at `src/modules/{Name}/router/routes.ts`
- Default export is `RouteRecordRaw[]`
- Use lazy imports for components
- Wrap with layout via parent route + `children` (if the project uses layout routes)
- Auth meta matches project convention (boolean flag, helper functions, beforeEnter, etc.)
- `meta.title`, `meta.breadcrumb` for chrome integration
- Route names from `./constants.ts` enum (ROUTE-002)
- Dynamic params use shared patterns if the project provides them

## Key Points

- One `routes.ts` per module
- Default export, `RouteRecordRaw[]`, lazy component imports
- Match the project's auth-meta convention — don't invent one
- Always use route name constants, never strings
- Use shared URL patterns if the project provides them
- See ROUTE-002 for route name constants
- See LAYOUT-001 for breadcrumb integration
