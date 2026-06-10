# Routing — pages

A **page** is the route-level component a router record renders. Same anatomy as any component, plus: it reads route params, owns the route's data, handles loading/error/empty states, and composes presentational components.

## Shape

```tsx
// pages/users/UserDetailPage.tsx
import { useParams } from 'react-router-dom'
import { useUser } from '@/data/users'
import { UserCard } from '@/features/users/components/UserCard'

export default function UserDetailPage() {
  const { id = '' } = useParams()
  const { data: user, isPending, isError, error } = useUser(id)

  if (isPending) return <p>Loading…</p>
  if (isError) return <p role="alert">{error.message}</p>
  if (!user) return <p>Not found.</p>
  return <UserCard user={user} />
}
```

## Conventions

- **`{Name}Page.tsx`** in `pages/` (or the project's route-component folder). Lazy-loaded by the router. A **default export** pairs cleanly with `lazy(() => import(...))`.
- **Read params** with `useParams()`, navigate with `useNavigate()`.
- **Pages own data**: call query hooks here, pass plain data to presentational components.
- **Always handle the four states**: loading, error, empty, loaded.
- **Thin pages**: orchestration + states; push UI into components, logic into hooks.

## Don't

- Don't put reusable UI directly in a page — extract a component.
- Don't fetch with raw `useEffect` — use a query hook.
- Don't scatter literal path strings — use `useNavigate`/`<Link>` with known paths.
