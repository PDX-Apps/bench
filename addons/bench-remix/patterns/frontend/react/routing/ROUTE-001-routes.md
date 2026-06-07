---
mode: replace
---
# Routing — Remix / React Router v7 (framework mode)

Routing is **file-based** (`app/routes/`). Each route module exports a default component plus optional `loader` (read) and `action` (write). Nested routes render via `<Outlet />`.

```
app/
  root.tsx                 # root layout (<html>, <Outlet/>)
  routes/
    _index.tsx             # /
    users._index.tsx       # /users
    users.$id.tsx          # /users/:id
    _auth.login.tsx        # /login  (pathless layout segment _auth)
```

## Route module — loader + component

```tsx
// app/routes/users.$id.tsx
import { useLoaderData, type LoaderFunctionArgs } from 'react-router'
import { getUser } from '@/data/users.server'

export async function loader({ params }: LoaderFunctionArgs) {
  const user = await getUser(params.id!)
  if (!user) throw new Response('Not found', { status: 404 })
  return { user }
}

export default function UserRoute() {
  const { user } = useLoaderData<typeof loader>()   // typed from the loader
  return <UserCard user={user} />
}
```

## Layout route + Outlet

```tsx
// app/root.tsx
import { Outlet, Links, Scripts } from 'react-router'
export default function Root() {
  return <html><body><nav>{/* … */}</nav><Outlet /><Scripts /></body></html>
}
```

## Conventions

- **File routes** with dot-delimited nesting; **`loader`** for reads (server), **`action`** for writes (server), default export = the component.
- **`useLoaderData<typeof loader>()`** for typed route data; **`<Form method="post">`** + `action` for mutations (progressive enhancement, no manual fetch).
- **Navigation**: `<Link to>` / `<NavLink>` / `useNavigate`; **errors** via `ErrorBoundary` export; redirects via `throw redirect('/login')` in a loader/action.
- Server-only modules end in `.server.ts` so they're tree-shaken out of the client bundle.

## See also

- [QUERY-001](../data/QUERY-001-tanstack-query.md) (loaders/actions are the data layer)
