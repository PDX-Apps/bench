---
mode: replace
---
# Data fetching — Remix / React Router v7 (loaders & actions)

Data flows through **route `loader`s** (read, server) and **`action`s** (write, server) — not a client query library. The framework handles fetching, revalidation after actions, and pending/error UI.

## Read — `loader`

```tsx
// server-only fetchers
// app/data/users.server.ts
export async function getUsers() { return db.user.findMany() }
```

```tsx
// route module
export async function loader() {
  return { users: await getUsers() }
}
export default function Users() {
  const { users } = useLoaderData<typeof loader>()
  return <ul>{users.map((u) => <li key={u.id}>{u.email}</li>)}</ul>
}
```

## Write — `action` + `<Form>`

```tsx
import { Form, redirect, type ActionFunctionArgs } from 'react-router'

export async function action({ request }: ActionFunctionArgs) {
  const form = await request.formData()
  await createUser({ email: String(form.get('email')) })
  return redirect('/users')   // loaders auto-revalidate after an action
}

export default function NewUser() {
  return <Form method="post"><input name="email" /><button>Create</button></Form>
}
```

## Conventions

- **Loaders read, actions write** — both run on the server; return plain data (typed via `typeof loader`).
- **`<Form>` + action** for mutations (works without JS); after an action, affected loaders **revalidate automatically** — no manual cache invalidation.
- **Pending UI**: `useNavigation()` / `useFetcher()` for optimistic + in-flight states.
- **`.server.ts`** for server-only modules. Reach for a client query lib only for genuinely client-driven data outside the route data flow.
