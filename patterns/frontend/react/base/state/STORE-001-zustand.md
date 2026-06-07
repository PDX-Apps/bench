# Zustand stores

Global/shared **client state** with Zustand — a hook-based store, minimal boilerplate.

## When

- State shared across unrelated components: session/user, UI preferences (theme, sidebar), a cross-page wizard.
- **Not for server data** — cached API data belongs in query hooks ([QUERY-001](../data/QUERY-001-tanstack-query.md)), not a Zustand store.

## Shape — typed `create` with selectors

```ts
// stores/session.ts
import { create } from 'zustand'
import type { User } from '@/types/user'

interface SessionState {
  user: User | null
  isAuthenticated: boolean
  setUser: (user: User | null) => void
  clear: () => void
}

export const useSessionStore = create<SessionState>((set) => ({
  user: null,
  isAuthenticated: false,
  setUser: (user) => set({ user, isAuthenticated: user !== null }),
  clear: () => set({ user: null, isAuthenticated: false }),
}))
```

Usage — **select narrowly** to avoid needless re-renders:

```ts
const user = useSessionStore((s) => s.user)          // re-renders only when user changes
const setUser = useSessionStore((s) => s.setUser)
```

## Conventions

- **`use{Name}Store`** export, typed `create<State>()`. State + actions in one interface; actions call `set`/`get`.
- **Select with a function** (`useStore((s) => s.field)`) — never destructure the whole store (re-renders on every change). For multiple fields, use `useShallow`.
- **Derived values**: compute in the selector or a small hook; keep raw state minimal.
- **Middleware** (`persist`, `devtools`, `immer`) only as needed; keep stores small + one-domain.

## Don't

- Don't cache server responses here — that's a query's job (caching, invalidation, refetch).
- Don't subscribe to the whole store object; select narrowly.
- Don't put one mega-store for everything.

## See also

- [QUERY-001](../data/QUERY-001-tanstack-query.md) (server state) · [HOOK-001](../hooks/HOOK-001-conventions.md)
