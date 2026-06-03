# LAYOUT-001-layouts

## Pattern

Layout components wrap route content with shared chrome (header, sidebar, footer). They live in `src/layouts/` (project-wide) or `src/modules/{Name}/layouts/`. The layout renders `<Outlet />` from React Router where the matched child route appears.

## Typical Layout Types

| Layout | Used For |
|--------|----------|
| `AppLayout` | Authenticated app routes (default) |
| `GuestLayout` | Auth pages (login, signup, password reset) |
| `LandingLayout` | Public marketing pages |

## Structure

```tsx
import { Outlet, useMatches } from 'react-router-dom';
import { useSessionStore } from 'src/stores/sessionStore';
import { AppHeader } from '../components/AppHeader';
import { AppSidebar } from '../components/AppSidebar';
import { useBreadcrumbs } from 'src/hooks/useBreadcrumbs';
import { useDocumentTitle } from 'src/hooks/useDocumentTitle';

export function AppLayout() {
  const user = useSessionStore((s) => s.user);
  const breadcrumbs = useBreadcrumbs();
  useDocumentTitle();

  return (
    <div className="app-layout">
      <AppHeader breadcrumbs={breadcrumbs} />
      <AppSidebar user={user} />
      <main className="app-page-container">
        <Outlet />
      </main>
    </div>
  );
}
```

If the project uses a UI library (MUI's `<Container>`, Radix layouts, etc.), substitute its primitives.

## Usage in Routes

The layout is the parent route's `element`; child routes appear in `<Outlet />`:

```typescript
const routes: RouteObject[] = [
  {
    path: '/',
    element: <AppLayout />,
    loader: protectedLoader,
    children: [
      { path: 'bills', element: <BillsPage /> },
      { path: 'households', element: <HouseholdsPage /> },
    ],
  },
];
```

## Multiple Layouts

For different chrome per section (e.g., admin vs user), define layouts as siblings:

```typescript
{
  path: '/',
  children: [
    { element: <AppLayout />, children: [/* user routes */] },
    { path: 'admin', element: <AdminLayout />, children: [/* admin routes */] },
    { path: 'auth', element: <GuestLayout />, children: [/* login, signup */] },
  ],
}
```

## Breadcrumb Integration

Layouts read breadcrumb metadata from the matched routes via `useMatches()`:

```typescript
import { useMatches } from 'react-router-dom';

export function useBreadcrumbs() {
  const matches = useMatches();
  return matches
    .filter((m) => (m.handle as any)?.breadcrumb)
    .map((m) => {
      const bc = (m.handle as any).breadcrumb;
      return {
        label: typeof bc.label === 'function' ? bc.label(m.params, m.data) : bc.label,
        to: m.pathname,
        icon: bc.icon,
      };
    });
}
```

## Conventions

- Suffix: `*Layout.tsx`
- Layouts contain only chrome — they don't fetch domain data
- One `<Outlet />` per layout
- Pull session via the project's session store
- Pull breadcrumbs via `useBreadcrumbs()` (project hook)
- Page title via `useDocumentTitle()` reading `route.handle.title`

## Persisted Suspense Boundary

Wrap `<Outlet />` in `<Suspense>` so lazy page loads show a fallback:

```tsx
import { Suspense } from 'react';

export function AppLayout() {
  return (
    <div>
      <AppHeader />
      <main>
        <Suspense fallback={<PageSkeleton />}>
          <Outlet />
        </Suspense>
      </main>
    </div>
  );
}
```

## Key Points

- Suffix: `*Layout.tsx`, lives in `src/layouts/` or per-module `layouts/`
- Single `<Outlet />` per layout for child routes
- Wrap `<Outlet />` in `<Suspense>` for lazy pages
- Don't fetch domain data — that's the Page's job
- Discover UI library + session/breadcrumb conventions from existing layouts
