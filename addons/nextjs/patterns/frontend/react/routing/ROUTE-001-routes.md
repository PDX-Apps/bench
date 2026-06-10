---
mode: replace
---
# Routing — Next.js App Router

Routing is **file-based** under `app/`. A folder = a route segment; special files define its parts. No route array, no `<RouterProvider>`.

```
app/
  layout.tsx            # root layout (persistent shell, <html><body>)
  page.tsx              # /
  users/
    page.tsx            # /users
    [id]/page.tsx       # /users/:id   (dynamic segment)
  (auth)/               # route group (no URL segment)
    login/page.tsx      # /login
```

## Layout (persistent shell)

```tsx
// app/layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header>{/* nav */}</header>
        <main>{children}</main>   {/* nested pages/layouts render here */}
      </body>
    </html>
  )
}
```

Nested `layout.tsx` files wrap their segment and persist across child navigations.

## Page — async Server Component, params is a Promise (Next 15)

```tsx
// app/users/[id]/page.tsx
import { getUser } from '@/data/users'

export default async function UserPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const user = await getUser(id)
  if (!user) notFound()
  return <UserCard user={user} />
}
```

## Conventions

- **Server Components by default**; add `'use client'` only for interactivity (state, effects, event handlers, browser APIs).
- **`page.tsx`** = a route; **`layout.tsx`** = persistent shell; `loading.tsx`/`error.tsx`/`not-found.tsx` for states; **`[param]`** dynamic, **`(group)`** route groups.
- **`params` and `searchParams` are Promises** in Next 15 — `await` them.
- **Navigation**: `<Link href>` and `useRouter()` from `next/navigation`.
- **Mutations**: Server Actions (`'use server'`) for forms/writes; `revalidatePath`/`revalidateTag` after.
