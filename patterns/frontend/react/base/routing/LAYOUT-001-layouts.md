# Routing — layouts

A **layout** is the persistent shell around pages — header, nav, footer — that stays mounted while page content swaps. In React Router, a layout is a component that renders `<Outlet />` and is used as a parent route.

## The core idea

```tsx
// layouts/AppLayout.tsx
import { Outlet, NavLink, Link } from 'react-router-dom'
import styles from './AppLayout.module.css'

export function AppLayout() {
  return (
    <div className={styles.layout}>
      <header className={styles.header}>
        <Link to="/">Acme</Link>
        <nav>
          <NavLink to="/users">Users</NavLink>
        </nav>
      </header>

      <main className={styles.main}>
        {/* child route renders here; the shell persists across navigation */}
        <Outlet />
      </main>

      <footer>© Acme</footer>
    </div>
  )
}
```

Wire it as a parent route (see [ROUTE-001](./ROUTE-001-routes.md)):

```tsx
{ element: <AppLayout />, children: [ { index: true, element: <HomePage /> } ] }
```

## Multiple layouts

Most apps need an authenticated **app** shell and a minimal **guest/auth** shell — two layout components, each a parent route. Nest auth guards by wrapping the layout element (or a `loader`). Shared sub-layouts (e.g. a settings sidebar) are just nested layout routes with their own `<Outlet />`.

## Conventions

- **`{Name}Layout.tsx`** in `layouts/`; renders `<Outlet />` where pages go. Structure + persistent chrome only — no page logic or data fetching.
- **`<NavLink>`** for nav (active styling), `<Link>` otherwise.
- Layout = structure; theme/spacing come from the styling system ([STYLE-001](../styling/STYLE-001-conventions.md)). If the project uses a UI library, use its layout primitives (AppBar/Drawer) and match them.

## Don't

- Don't fetch data or hold business logic in a layout.
- Don't duplicate the shell in every page — use a layout route + `<Outlet />`.

## See also

- [ROUTE-001](./ROUTE-001-routes.md) · [PAGE-001](./PAGE-001-pages.md) · [STYLE-001](../styling/STYLE-001-conventions.md)
