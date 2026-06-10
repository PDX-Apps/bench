---
mode: replace
---
# Data fetching — Nuxt (useFetch / useAsyncData)

Fetch with Nuxt's SSR-aware composables — data is fetched on the server and hydrated on the client (no flash, no double-fetch). Use `$fetch` for event-driven calls (mutations).

## Read — `useFetch`

```vue
<script setup lang="ts">
import type { User } from '~/types/user'
const { data: users, pending, error, refresh } = await useFetch<User[]>('/api/users')
</script>
```

Reactive params refetch automatically:

```ts
const id = useRoute().params.id
const { data: user } = await useFetch(() => `/api/users/${id}`)
```

Use `useAsyncData('key', () => $fetch(...))` when you need a custom fetcher or explicit cache key.

## Server routes (the API layer)

```ts
// server/api/users/index.get.ts
export default defineEventHandler(async () => {
  return await db.user.findMany()   // runs server-side only
})
```

## Write — `$fetch` + refresh

```ts
async function createUser(payload: CreateUserPayload) {
  await $fetch('/api/users', { method: 'POST', body: payload })
  await refresh()   // re-pull the list
}
```

## Shared SSR-safe state — `useState`

For state that must survive SSR→client hydration and be shared across components, use Nuxt's **`useState`** (keyed, SSR-safe) — not a module-level `ref`, which leaks between requests on the server:

```ts
const cart = useState<CartItem[]>("cart", () => [])
```

Use Pinia for larger client stores; `useState` for small cross-component values.

## Conventions

- **`useFetch`/`useAsyncData`** for page/component data (SSR + dedup + caching); **`$fetch`** for mutations and event handlers.
- **Reactive URL** as a function (`() => \`/api/users/${id}\``) so it refetches when inputs change.
- **`server/api/`** holds server-only logic + secrets — the browser never sees them.
- Don't add TanStack Query on top — Nuxt's composables are the data layer. (Pinia Colada has a Nuxt module if you want a richer client cache.)
