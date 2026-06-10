---
mode: replace
---
# Data fetching — Pinia Colada

Server state — fetching, caching, background refetch, mutations — via **`@pinia/colada`** (the Vue-native data layer, tightly integrated with Pinia reactivity). The query cache *is* the server-state store; no "service class" layer.

## Setup (once, after Pinia)

```ts
import { createPinia } from 'pinia'
import { PiniaColada } from '@pinia/colada'

app.use(createPinia())
app.use(PiniaColada, { queryOptions: { staleTime: 30_000 } })
```

## Read — wrap `useQuery` in a composable per resource

```ts
// data/users.ts
import { useQuery, useMutation, useQueryCache } from '@pinia/colada'
import { toValue, type MaybeRefOrGetter } from 'vue'
import { http } from '@/lib/http'
import type { User, CreateUserPayload } from '@/types/user'

export const userKeys = {
  all: ['users'] as const,
  detail: (id: MaybeRefOrGetter<string>) => ['users', toValue(id)] as const,
}

export function useUsers() {
  return useQuery({ key: userKeys.all, query: (): Promise<User[]> => http.get('/users') })
}

export function useUser(id: MaybeRefOrGetter<string>) {
  return useQuery({
    key: () => userKeys.detail(id),       // function key → reactive; refetches when id changes
    query: () => http.get<User>(`/users/${toValue(id)}`),
  })
}
```

Component:

```vue
<script setup lang="ts">
const { data: users, isPending, state } = useUsers()
</script>
<template>
  <p v-if="isPending">Loading…</p>
  <p v-else-if="state.error" role="alert">{{ state.error.message }}</p>
  <ul v-else><li v-for="u in users" :key="u.id">{{ u.email }}</li></ul>
</template>
```

## Write — `useMutation` + invalidate via the query cache

```ts
export function useCreateUser() {
  const cache = useQueryCache()
  return useMutation({
    mutation: (payload: CreateUserPayload) => http.post<User>('/users', payload),
    onSettled: () => cache.invalidateQueries({ key: userKeys.all }),
  })
}
```

```ts
const { mutate: createUser, asyncStatus } = useCreateUser()
createUser(payload)
```

## Optimistic update — snapshot → write → rollback

For instant feedback, update the cache in `onMutate`, roll back in `onError`, reconcile in `onSettled`:

```ts
export function useRenameOrder() {
  const cache = useQueryCache()
  return useMutation({
    mutation: (o: { id: string; reference: string }) => http.patch<Order>(`/orders/${o.id}`, o),
    onMutate(o) {
      const previous = cache.getQueryData<Order>(['orders', o.id])
      cache.cancelQueries({ key: ['orders', o.id] })          // stop in-flight refetches
      cache.setQueryData(['orders', o.id], { ...previous, ...o } as Order)
      return { previous }                                      // context → onError/onSettled
    },
    onError: (_err, o, { previous }) => cache.setQueryData(['orders', o.id], previous),  // rollback
    onSettled: (_d, _e, o) => cache.invalidateQueries({ key: ['orders', o.id] }),
  })
}
```

## Dependent / disabled queries

Gate a query on a prerequisite with `enabled` (a getter so it stays reactive):

```ts
export function useOrderInvoice(orderId: MaybeRefOrGetter<string | undefined>) {
  return useQuery({
    key: () => ['orders', toValue(orderId), 'invoice'],
    query: () => http.get(`/orders/${toValue(orderId)}/invoice`),
    enabled: () => !!toValue(orderId),     // doesn't run until the id exists
  })
}
```

## Conventions

- **One composable per query/mutation** (`use{Resource}`) + a typed **key factory**.
- **Pinia Colada API**: `useQuery({ key, query })`, `useMutation({ mutation, onSettled })`, `useQueryCache().invalidateQueries({ key })`.
- **Reactive keys**: pass a function `key: () => [...]` so the query refetches when inputs change.
- **State**: `data`, `isPending`, `asyncStatus` ('idle'|'loading'), and `state.error` — render loading/error/data.
- **Mutations invalidate** affected keys in `onSettled`; cache refetches what's in use automatically.
- **The HTTP client** (`@/lib/http`) owns base URL/auth/error shape.

## Don't

- Don't cache server data in a plain Pinia store, or write a `*Service` class layer.
- Don't fetch in `onMounted` with manual refs when Pinia Colada is present.
- Don't inline keys in components — use the key factory.
