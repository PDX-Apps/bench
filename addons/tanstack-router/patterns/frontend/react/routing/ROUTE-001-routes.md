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
  // ... query + four states (see QUERY-001 / PAGE-001)
}
```

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

## See also

- [PAGE-001](./PAGE-001-pages.md) · [LAYOUT-001](./LAYOUT-001-layouts.md) · [QUERY-001](../data/QUERY-001-tanstack-query.md)
