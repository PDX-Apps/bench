# ROUTE-001-route-definitions

## Pattern

Each module declares its routes in `src/modules/{Name}/router/routes.ts`. The project's router config collects routes from all modules — either via `createBrowserRouter` configuration (data-router API, recommended) or declarative `<Routes>` elements.

This document assumes **React Router v6+** (data-router API). If the project uses TanStack Router, follow that convention.

## Structure (data-router API)

```typescript
import type { RouteObject } from 'react-router-dom';
import { lazy } from 'react';
import { BillRoutes } from './constants';

const ULID_PATTERN = ':id([0-9A-HJKMNP-TV-Z]{26})';

const BillsPage = lazy(() => import('../pages/BillsPage'));
const BillPage = lazy(() => import('../pages/BillPage'));

const routes: RouteObject[] = [
  {
    path: '/bills',
    handle: { requiresAuth: true },   // project-specific meta convention
    children: [
      {
        index: true,
        id: BillRoutes.LIST,
        element: <BillsPage />,
        handle: {
          title: 'Bills',
          breadcrumb: { label: 'bill.breadcrumb.list', icon: 'list' },
        },
      },
      {
        path: ':id',
        id: BillRoutes.DETAIL,
        element: <BillPage />,
        handle: {
          title: 'Bill',
          breadcrumb: { label: (params, ctx) => ctx?.name ?? params.id },
        },
      },
    ],
  },
];

export default routes;
```

## Layout via Parent Route Element

If the project uses layout routes, the parent route declares the layout element with an `<Outlet />` for children:

```typescript
const routes: RouteObject[] = [
  {
    path: '/bills',
    element: <AppLayout />,   // contains <Outlet />
    children: [
      { index: true, element: <BillsPage /> },
      { path: ':id', element: <BillPage /> },
    ],
  },
];
```

## Auth Meta (project-specific convention)

React Router doesn't have a built-in auth concept — projects implement it via:

- `handle` field with custom shape + a global `<RouteGuard />` element that reads it
- `loader` functions that throw a redirect for unauthenticated users
- Wrapping protected routes with an `<AuthGate />` element

Discover by reading sibling routes. Don't introduce a new mechanism.

```typescript
// Loader-based auth example
import { redirect } from 'react-router-dom';
import { getSession } from 'src/services/auth';

export const protectedLoader = async () => {
  const session = await getSession();
  if (!session) throw redirect('/login');
  return session;
};

const routes: RouteObject[] = [
  {
    path: '/bills',
    loader: protectedLoader,
    children: [...],
  },
];
```

## Lazy Loading

Always lazy-import page components for code splitting:

```typescript
import { lazy } from 'react';
const BillsPage = lazy(() => import('../pages/BillsPage'));

// In the route:
{ element: <BillsPage /> }
```

Wrap the router in `<Suspense fallback={<Skeleton />}>` at the app root.

## URL Patterns

React Router v6 doesn't support regex path constraints directly. For ID validation, use a `loader` or `<RouteGuard />` that validates `params.id`:

```typescript
{
  path: ':id',
  loader: ({ params }) => {
    if (!isValidUlid(params.id)) throw redirect('/404');
    return null;
  },
}
```

## Route Names (Constants)

Use the module's route enum (see ROUTE-002) — never hardcoded strings:

```typescript
import { BillRoutes } from './constants';

{ id: BillRoutes.LIST, element: <BillsPage /> }
```

The route `id` field gives you stable navigation: `useNavigate()(`/route-by-id/${BillRoutes.DETAIL}`)`... actually React Router doesn't navigate by id natively — you'd combine ID with a helper:

```typescript
// src/router/helpers.ts
const pathByRouteId: Record<string, (params?: Record<string, string>) => string> = {
  [BillRoutes.LIST]: () => '/bills',
  [BillRoutes.DETAIL]: (p) => `/bills/${p!.id}`,
};

export function pathFor(routeId: string, params?: Record<string, string>): string {
  return pathByRouteId[routeId](params);
}
```

## Title + Breadcrumb Meta

Custom `handle` fields contain page-specific metadata. A global hook (e.g., `useMatches()`) reads them:

```typescript
import { useMatches } from 'react-router-dom';

function useDocumentTitle() {
  const matches = useMatches();
  const match = matches.findLast((m) => (m.handle as any)?.title);
  useEffect(() => {
    document.title = (match?.handle as any)?.title ?? 'App';
  }, [match]);
}
```

## Conventions

- Routes file at `src/modules/{Name}/router/routes.ts`
- Default export is `RouteObject[]`
- Use `lazy()` for page imports
- Wrap with layout via parent route + `<Outlet />`
- Route IDs from `./constants.ts` enum (ROUTE-002)
- Custom `handle` field for auth meta, title, breadcrumbs

## Key Points

- One `routes.ts` per module
- React Router v6+ data-router API (`RouteObject[]`)
- Lazy imports for code splitting
- Layout via parent route + `<Outlet />` (if project uses layout routes)
- Auth: `loader` redirect OR `handle` meta + global guard
- See ROUTE-002 for route id constants
- See LAYOUT-001 for layout components
