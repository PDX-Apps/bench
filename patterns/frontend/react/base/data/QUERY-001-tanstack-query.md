# Data fetching — TanStack Query (React Query)

Server state — fetching, caching, background refetch, mutations — via **`@tanstack/react-query`**. The query cache *is* the server-state store; there's no separate "service class" layer.

## Setup (once, at the app root)

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <App />
  </QueryClientProvider>,
)
```

## Read — wrap `useQuery` in a hook per resource

Co-locate query keys + fetchers so components don't repeat them.

```ts
// data/users.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { http } from '@/lib/http'
import type { User, CreateUserPayload } from '@/types/user'

export const userKeys = {
  all: ['users'] as const,
  detail: (id: string) => ['users', id] as const,
}

export function useUsers() {
  return useQuery({ queryKey: userKeys.all, queryFn: (): Promise<User[]> => http.get('/users') })
}

export function useUser(id: string) {
  return useQuery({
    queryKey: userKeys.detail(id),
    queryFn: () => http.get<User>(`/users/${id}`),
    enabled: !!id,
  })
}
```

Component:

```tsx
const { data: users, isPending, isError, error } = useUsers()
if (isPending) return <p>Loading…</p>
if (isError) return <p role="alert">{error.message}</p>
return <ul>{users.map((u) => <li key={u.id}>{u.email}</li>)}</ul>
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

```tsx
const { mutate: createUser, isPending } = useCreateUser()
createUser(payload, { onSuccess: () => navigate('/users') })
```

## Conventions

- **One hook per query/mutation** (`use{Resource}`, `useCreate{Resource}`) + a typed **query-key factory** (`userKeys`).
- **Object signatures** (v5): `useQuery({ queryKey, queryFn })`, `invalidateQueries({ queryKey })`.
- **`enabled`** to gate dependent queries; state flags `isPending`/`isError`/`error`/`isFetching` — render all.
- **Mutations invalidate** affected keys in `onSuccess`; reach for optimistic updates only when needed.
- **The HTTP client** (`@/lib/http`) is the only place that knows base URL, auth headers, error shape.

## Don't

- Don't cache server data in a Zustand store, or write a `*Service` class layer.
- Don't fetch in `useEffect` with manual `useState` when React Query is present.
- Don't inline `queryKey` strings in components — use the key factory.
