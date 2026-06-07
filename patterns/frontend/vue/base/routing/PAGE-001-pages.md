# Routing — pages

A **page** is the route-level component a router record points at. Same anatomy as any component ([COMPONENT-001](../components/COMPONENT-001-conventions.md)), plus: it owns the route's data, handles loading/empty/error states, and composes presentational components.

## Shape

```vue
<!-- pages/users/UserDetailPage.vue -->
<script setup lang="ts">
import { useUser } from '@/data/users'
import UserCard from '@/features/users/components/UserCard.vue'

// route param arrives as a prop (router record has `props: true`)
const props = defineProps<{ id: string }>()

const { data: user, isPending, isError, error } = useUser(() => props.id)
</script>

<template>
  <section>
    <p v-if="isPending">Loading…</p>
    <p v-else-if="isError" role="alert">{{ error.message }}</p>
    <UserCard v-else-if="user" :user="user" />
    <p v-else>Not found.</p>
  </section>
</template>
```

## Conventions

- **`{Name}Page.vue`** in `pages/` (or the project's route-component folder). Lazy-loaded by the router ([ROUTE-001](./ROUTE-001-routes.md)).
- **Route params as props** (`props: true`) — keeps pages testable without mocking `useRoute()`.
- **Pages own data**: call query composables ([QUERY-001](../data/QUERY-001-tanstack-query.md)) here, pass plain data down to presentational components.
- **Always handle the four states**: loading, error, empty, loaded. Never render assuming data exists.
- **Thin pages**: orchestration + states only; push UI into components, logic into composables.
- **Navigation** via named routes (`router.push({ name, params })`).

## Don't

- Don't put reusable UI directly in a page — extract a component.
- Don't access data with bare `fetch` in `onMounted` — use a query composable.
- Don't read params via `useRoute()` when `props: true` gives them as typed props.

## See also

- [ROUTE-001](./ROUTE-001-routes.md) · [LAYOUT-001](./LAYOUT-001-layouts.md) · [QUERY-001](../data/QUERY-001-tanstack-query.md) · [COMPONENT-001](../components/COMPONENT-001-conventions.md)
