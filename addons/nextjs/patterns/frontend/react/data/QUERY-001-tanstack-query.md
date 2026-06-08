---
mode: replace
---
# Data fetching — Next.js (App Router)

Fetch on the **server** in async Server Components with the extended `fetch` (caching built in). Use a client query library (TanStack Query) only for genuinely client-side/interactive data.

## Server data (the default)

```tsx
// data/users.ts — server-only fetchers
import 'server-only'
import type { User } from '@/types/user'

export async function getUsers(): Promise<User[]> {
  const res = await fetch(`${process.env.API_URL}/users`, { next: { revalidate: 60 } })
  if (!res.ok) throw new Error('Failed to load users')
  return res.json()
}
```

```tsx
// app/users/page.tsx (Server Component)
import { getUsers } from '@/data/users'
export default async function UsersPage() {
  const users = await getUsers()
  return <ul>{users.map((u) => <li key={u.id}>{u.email}</li>)}</ul>
}
```

**Caching per request** (Next 15 — uncached by default):
- `fetch(url, { cache: 'force-cache' })` — static/cached until invalidated
- `fetch(url, { cache: 'no-store' })` — always dynamic
- `fetch(url, { next: { revalidate: 60 } })` — ISR / time-based
- Parallelize independent fetches with `Promise.all`.

## Mutations — Server Actions

```tsx
// app/users/actions.ts
'use server'
import { revalidatePath } from 'next/cache'
export async function createUser(formData: FormData) {
  await fetch(`${process.env.API_URL}/users`, { method: 'POST', body: JSON.stringify(/* ... */) })
  revalidatePath('/users')
}
```

## Client data (when needed)

For interactive client components that fetch (search-as-you-type, infinite scroll), use **TanStack Query** inside a `'use client'` component with a `QueryClientProvider` in a client boundary — same API as the base pattern.

## Conventions

- **Prefer server fetching** + caching over client queries; pass server data down as props.
- **`server-only`** guards server fetchers; secrets never reach the client.
- **Mutations = Server Actions** + `revalidatePath`/`revalidateTag`; avoid client round-trips for writes.
- Don't wrap the whole app in TanStack Query — reserve it for true client-interactive data.

## See also

- [ROUTE-001](../routing/ROUTE-001-routes.md)
