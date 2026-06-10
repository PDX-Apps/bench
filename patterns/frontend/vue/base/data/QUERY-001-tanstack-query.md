# Data fetching — TanStack Query (Vue Query)

Server state — fetching, caching, background refetch, mutations — via **`@tanstack/vue-query`**. This replaces hand-rolled "service class" + store-caching layers: the query cache *is* the server-state store.

> If the project uses **Pinia Colada** instead (Vue-native, similar API), match that — it's the `pinia-colada` addon. If it has no query library at all, fetch in a composable with `ref` loading/error state and recommend adopting one.

## Setup (once, in the app entry)

```ts
import { VueQueryPlugin } from '@tanstack/vue-query'
createApp(App).use(VueQueryPlugin).mount('#app')
```

## Read — wrap `useQuery` in a composable per resource

Keep query keys + fetchers in one place so components don't repeat them.

```ts
// data/users.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { toValue, type MaybeRefOrGetter } from 'vue'
import { http } from '@/lib/http'
import type { User, CreateUserPayload } from '@/types/user'

export const userKeys = {
  all: ['users'] as const,
  detail: (id: MaybeRefOrGetter<string>) => ['users', toValue(id)] as const,
}

export function useUsers() {
  return useQuery({
    queryKey: userKeys.all,
    queryFn: (): Promise<User[]> => http.get('/users'),
  })
}

export function useUser(id: MaybeRefOrGetter<string>) {
  return useQuery({
    queryKey: userKeys.detail(id),
    queryFn: () => http.get<User>(`/users/${toValue(id)}`),
  })
}
```

Component:

```vue
<script setup lang="ts">
const { data: users, isPending, isError, error } = useUsers()
</script>
<template>
  <p v-if="isPending">Loading…</p>
  <p v-else-if="isError" role="alert">{{ error.message }}</p>
  <ul v-else><li v-for="u in users" :key="u.id">{{ u.email }}</li></ul>
</template>
```

## Write — `useMutation` + invalidate

```ts
export function useCreateUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreateUserPayload) => http.post<User>('/users', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: userKeys.all }),
  })
}
```

```ts
const { mutate: createUser, isPending } = useCreateUser()
createUser(payload, { onSuccess: () => router.push('/users') })
```

## Conventions

- **One composable per query/mutation**, named `use{Resource}` / `useCreate{Resource}`; co-locate with a typed **query-key factory** (`userKeys`).
- **Object signatures** (TanStack Query v5): `useQuery({ queryKey, queryFn })`, `invalidateQueries({ queryKey })`.
- **Reactive keys**: accept `MaybeRefOrGetter` and `toValue()` so the query refetches when inputs change.
- **State flags**: `isPending` (no data yet), `isError`/`error`, `isFetching` (background). Render all three.
- **Mutations invalidate** the affected keys in `onSuccess`; don't manually patch the cache unless you need optimistic updates.
- **The HTTP client** (`@/lib/http` — a thin `fetch`/`axios` wrapper) is the only place that knows base URL, auth headers, error shape. Queries call it.

## Don't

- Don't cache server data in a Pinia store, or write a `*Service` class layer — the query cache handles it.
- Don't fetch in `onMounted` with manual `ref`s when a query library is present.
- Don't put `queryKey` strings inline in components — use the key factory.
