# Routing — route definitions

React Router (v6.4+/v7) with the **data router** (`createBrowserRouter`): nested routes, layout routes, lazy pages.

> If the project uses **TanStack Router**, file-based routing, or a meta-framework router (Next.js/Remix), match that instead — those are addons/variants.

## Shape — `createBrowserRouter` with nested + layout routes

```tsx
// router/index.tsx
import { createBrowserRouter } from 'react-router-dom'
import { lazy } from 'react'
import { AppLayout } from '@/layouts/AppLayout'
import { RequireAuth } from '@/router/RequireAuth'

const HomePage = lazy(() => import('@/pages/HomePage'))
const UsersPage = lazy(() => import('@/pages/users/UsersPage'))
const UserDetailPage = lazy(() => import('@/pages/users/UserDetailPage'))

export const router = createBrowserRouter([
  {
    element: (
      <RequireAuth>
        <AppLayout />
      </RequireAuth>
    ),
    children: [
      { index: true, element: <HomePage /> },
      { path: 'users', element: <UsersPage /> },
      { path: 'users/:id', element: <UserDetailPage /> },
    ],
  },
  { path: '/login', lazy: () => import('@/pages/auth/LoginPage') },
  { path: '*', element: <NotFoundPage /> },
])
```

```tsx
// main.tsx
import { RouterProvider } from 'react-router-dom'
createRoot(el).render(<RouterProvider router={router} />)
```

## Auth guard (route wrapper)

```tsx
// router/RequireAuth.tsx
import { Navigate, useLocation } from 'react-router-dom'
import { useSessionStore } from '@/stores/session'

export function RequireAuth({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useSessionStore((s) => s.isAuthenticated)
  const location = useLocation()
  if (!isAuthenticated) return <Navigate to="/login" state={{ from: location }} replace />
  return children
}
```

## Conventions

- **Data router** (`createBrowserRouter` + `RouterProvider`) — the modern default over `<BrowserRouter><Routes>`.
- **Lazy-load pages** (`lazy(() => import(...))` or route `lazy`) for code splitting.
- **Layout routes** = a parent route with `element: <Layout />` rendering `<Outlet />`.
- **Read params with `useParams()`** in the page; navigate with `useNavigate()` / `<Link>` / `<NavLink>` — no hard-coded literal paths scattered around (centralize path builders if the app is large).
- **Auth** via a wrapper component (or a `loader` redirect in data-router style), not ad-hoc checks in pages.

## Don't

- Don't eagerly import every page (kills splitting).
- Don't use `<BrowserRouter>` + `<Routes>` for new data-driven apps unless the project already does.
- Don't put auth logic inside each page.
