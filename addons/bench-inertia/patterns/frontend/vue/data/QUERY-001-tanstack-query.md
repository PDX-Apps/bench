---
mode: replace
---
# Data — Inertia page props (Vue)

Page data arrives as **props from the controller** (`Inertia::render('Orders/Index', [...])`) — there is no client query library for page data.

```vue
<script setup>
import { defineProps } from 'vue'
import { Deferred } from '@inertiajs/vue3'

const props = defineProps({ orders: Object, stats: Object })
</script>

<template>
  <OrderTable :orders="orders.data" />
  <!-- deferred prop: rendered when the follow-up request resolves -->
  <Deferred data="stats">
    <template #fallback>Loading stats…</template>
    <StatsPanel :stats="stats" />
  </Deferred>
</template>
```

## Conventions

- **Props are server state** — the controller passes API Resources/paginators; the page reads `props`. Refresh by re-visiting (`router.reload({ only: ['orders'] })`).
- **Mutations**: submit with `useForm` (see INERTIA-002) — on success the server redirects and returns fresh props; no cache to invalidate.
- **Deferred props** (`Inertia::defer`) render via `<Deferred>`; **polling** via `router.reload` on an interval if needed.
- **Shared props** (auth, flash) come from `usePage().props`.
- Only reach for an ad-hoc client fetch (the project's HTTP lib) for genuinely client-only widgets — never for page data.

## Don't

- Don't install TanStack Query / a service layer for page data — props already are the data. Don't duplicate server state in a client cache.

## See also

- [ROUTE-001](../routing/ROUTE-001-routes.md) · laravel side: `<PLUGIN_ROOT>/patterns-built/laravel/inertia/INERTIA-001-pages.md`, `.../INERTIA-002-forms.md`
