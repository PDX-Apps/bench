---
mode: replace
---
# Data — Inertia page props (React)

Page data arrives as **props from the controller** (`Inertia::render('Orders/Index', [...])`) — no client query library for page data.

```tsx
import { Deferred, usePage } from '@inertiajs/react'

export default function OrdersIndex({ orders, stats }: OrdersIndexProps) {
  return (
    <>
      <OrderTable orders={orders.data} />
      {/* deferred prop: shown when the follow-up request resolves */}
      <Deferred data="stats" fallback={<p>Loading stats…</p>}>
        <StatsPanel stats={stats} />
      </Deferred>
    </>
  )
}
```

## Conventions

- **Props are server state** — the controller passes Resources/paginators; the page reads them. Refresh via `router.reload({ only: ['orders'] })`.
- **Mutations**: `useForm` — on success the server redirects with fresh props; nothing to invalidate.
- **Deferred props** via `<Deferred>`; **shared props** (auth, flash) via `usePage().props`.
- **Polling** via the v2 `usePoll(ms, { only: [...] })` helper; **infinite scroll / load-more** via server `Inertia::merge()` + the `<WhenVisible>` component.
- Reach for an ad-hoc client fetch only for client-only widgets — never page data.

## Don't

- Don't install TanStack Query / a service layer for page data. Don't mirror server state in a client cache.
