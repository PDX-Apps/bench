---
mode: replace
---
# Routing — Inertia (Vue)

There is **no client-side router**. Routes are Laravel routes; the server returns the page via `Inertia::render`. Navigate with `<Link>` / `router` from `@inertiajs/vue3`.

```vue
<script setup>
import { Link, router } from '@inertiajs/vue3'

const goToOrder = (id) => router.visit(`/orders/${id}`)
</script>

<template>
  <Link href="/orders">Orders</Link>
  <Link :href="`/orders/${order.id}`" prefetch>View</Link>
  <!-- partial reload: only re-fetch the `orders` prop -->
  <Link href="/orders?active=true" :only="['orders']">Active</Link>
</template>
```

## Conventions

- **Pages** live in `<!--bench:var:inertia_pages_dir;default:resources/js/Pages-->/{Dir}/{Page}.vue`; the name in `Inertia::render('Orders/Index')` maps here (configured in `createInertiaApp`'s `resolve`).
- **Navigation**: `<Link href>` for clicks; `router.visit/get/post/put/delete` programmatically. `<Link>` issues an XHR and swaps the page component — no full reload.
- **Partial reloads**: `:only="['prop']"` / `:except` to re-fetch a subset of props.
- **Prefetch** with `prefetch` on `<Link>`; **`preserveScroll`/`preserveState`** options where needed.
- Route URLs come from the server (use Ziggy's `route()` if installed) — don't maintain a client route table.

## Don't

- Don't add `vue-router` — Inertia owns navigation. Don't build a client route map; the server defines routes.
