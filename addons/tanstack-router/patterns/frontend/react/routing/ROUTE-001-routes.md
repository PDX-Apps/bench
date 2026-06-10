---
mode: replace
---
# Routing — TanStack Router (type-safe)

[TanStack Router](https://tanstack.com/router) with end-to-end type safety: typed params, search, and links. **File-based routing** (`@tanstack/router-plugin`, generates `routeTree.gen.ts`) is the recommended default; the example below is the equivalent code-based setup.

## Root + routes + router

```tsx
// router.tsx
import {
  createRootRoute, createRoute, createRouter, Outlet, Link,
} from '@tanstack/react-router'
import { AppLayout } from '@/layouts/AppLayout'

const rootRoute = createRootRoute({ component: () => <Outlet /> })

const appRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'app',
  component: AppLayout,            // a layout route: renders <Outlet/>
})

const indexRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/',
  component: lazyRouteComponent(() => import('@/pages/HomePage')),
})

const userDetailRoute = createRoute({
  getParentRoute: () => appRoute,
  path: 'users/$userId',
  component: lazyRouteComponent(() => import('@/pages/users/UserDetailPage')),
})

const routeTree = rootRoute.addChildren([
  appRoute.addChildren([indexRoute, userDetailRoute]),
])

export const router = createRouter({ routeTree, defaultPreload: 'intent' })

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
```

```tsx
// main.tsx
import { RouterProvider } from '@tanstack/react-router'
createRoot(el).render(<RouterProvider router={router} />)
```

## Layout route + typed params in a page

```tsx
// layouts/AppLayout.tsx
import { Outlet, Link } from '@tanstack/react-router'
export function AppLayout() {
  return <div><nav><Link to="/users">Users</Link></nav><main><Outlet /></main></div>
}
```

```tsx
// pages/users/UserDetailPage.tsx
import { useParams } from '@tanstack/react-router'
export default function UserDetailPage() {
  const { userId } = useParams({ from: '/users/$userId' }) // fully typed
  // ... query + four states
}
```

## Loaders + typed search params

A route can **load data before it renders** and **validate `?search` params** into a typed object — the headline type-safety feature:

```tsx
import { z } from 'zod'

const ordersSearch = z.object({ page: z.number().catch(1), status: z.enum(['open', 'paid']).optional() })

const ordersRoute = createRoute({
  getParentRoute: () => appRoute,
  path: 'orders',
  validateSearch: ordersSearch,                          // ?page=2&status=open → typed + defaulted
  loaderDeps: ({ search }) => ({ page: search.page }),   // re-run the loader when page changes
  loader: ({ deps }) => fetchOrders(deps.page),          // runs before the component renders
  component: OrdersPage,
})

function OrdersPage() {
  const orders = ordersRoute.useLoaderData()             // typed from the loader's return
  const { page, status } = ordersRoute.useSearch()       // typed from validateSearch
  // typed nav: <Link to="/orders" search={(prev) => ({ ...prev, page: prev.page + 1 })}>Next</Link>
}
```

Pick **loaders** for route-critical data (router shows pending/error UI, dedupes, preloads on intent) and TanStack Query for client-interactive data layered on top.

## Conventions

- **`createRootRoute` → `createRoute({ getParentRoute, path, component })` → `addChildren` → `createRouter({ routeTree })`** → `<RouterProvider>`.
- **File-based routing** (`routes/` + the Vite plugin) is preferred for non-trivial apps — match it if the project uses it; the code-based form above is the fallback.
- **Type-safe everything**: `<Link to="/users/$userId" params={{ userId }} />`, `useParams({ from })`, `useNavigate`, `useSearch` — params/search are typed; never hand-build path strings.
- **Layout routes** = a pathless/`id` route whose component renders `<Outlet />`.
- **Lazy** via `lazyRouteComponent(() => import(...))` (or file-based `.lazy.tsx`).
- **Auth** via a route `beforeLoad` redirect (`throw redirect({ to: '/login' })`), not ad-hoc checks in pages.
- **Data**: pair with TanStack Query (or use route `loader`s) — keep server state in the query cache.

## Don't

- Don't hand-build path strings — use typed `to`/`params`.
- Don't put auth checks inside each page — use `beforeLoad`.
- Don't eagerly import pages.
