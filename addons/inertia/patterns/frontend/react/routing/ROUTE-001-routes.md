---
mode: replace
---
# Routing — Inertia (React)

There is **no client-side router**. Routes are Laravel routes; the server returns the page via `Inertia::render`. Navigate with `<Link>` / `router` from `@inertiajs/react`.

```tsx
import { Link, router } from '@inertiajs/react'

export function Nav({ order }: { order: Order }) {
  return (
    <>
      <Link href="/orders">Orders</Link>
      <Link href={`/orders/${order.id}`} prefetch>View</Link>
      {/* partial reload: only re-fetch the `orders` prop */}
      <Link href="/orders?active=true" only={['orders']}>Active</Link>
      <button onClick={() => router.visit(`/orders/${order.id}`)}>Open</button>
    </>
  )
}
```

## Conventions

- **Pages** live in `<!--bench:var:inertia_pages_dir;default:resources/js/Pages-->/{Dir}/{Page}.tsx`; the `Inertia::render('Orders/Index')` name maps here (via `createInertiaApp`'s `resolve`).
- **Navigation**: `<Link href>` for clicks; `router.visit/get/post/...` programmatically — an XHR swaps the page component, no full reload.
- **Partial reloads**: `only={['prop']}` / `except`. **Prefetch** with `prefetch`; `preserveScroll`/`preserveState` options where needed.
- Route URLs come from the server (Ziggy's `route()` if installed) — no client route table.

## Don't

- Don't add `react-router` — Inertia owns navigation. Don't build a client route map.

## See also

- [QUERY-001](../data/QUERY-001-tanstack-query.md) (page data = props) · laravel side: `<PLUGIN_ROOT>/patterns-built/laravel/inertia/INERTIA-001-pages.md`
