# STORE-001-zustand-stores

## Pattern

Zustand is the de-facto modern React state library — small, hook-based, no Provider needed, TypeScript-friendly. Use it for global state shared across the app.

If the project uses Redux Toolkit, Jotai, or another state library, follow that convention instead — discover from sibling stores.

## When to Use a Store

- ✅ State that survives across route changes (current user session, app-wide settings)
- ✅ State shared across unrelated components (notifications, modals, theme)
- ❌ Page-local state — use `useState`
- ❌ Module-local state — use a custom hook
- ❌ Form state — use react-hook-form's local state
- ❌ Server data (use TanStack Query instead — it's the cache)

## Structure (Zustand)

```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { AuthService } from '../services/AuthService';
import { User, type IUser } from '../models/User';

interface SessionState {
  user: User | null;
  initialized: boolean;
}

interface SessionActions {
  setSession: (data: IUser) => void;
  clearSession: () => void;
  fetchSession: () => Promise<void>;
}

type SessionStore = SessionState & SessionActions;

export const useSessionStore = create<SessionStore>()(
  devtools(
    persist(
      (set, get) => ({
        user: null,
        initialized: false,

        setSession: (data) =>
          set({ user: User.fromApi(data), initialized: true }, false, 'session/setSession'),

        clearSession: () =>
          set({ user: null }, false, 'session/clearSession'),

        fetchSession: async () => {
          if (get().initialized) return;
          const data = await AuthService.fetchSession();
          if (data) get().setSession(data);
          else set({ initialized: true });
        },
      }),
      { name: 'session-store' },  // persist key
    ),
    { name: 'SessionStore' },  // devtools name
  ),
);
```

## Selectors

Always select the slice you need — never destructure the whole store (causes re-renders on any change):

```tsx
// ✅ Right — re-renders only when `user` changes
const user = useSessionStore((state) => state.user);

// ✅ Stable selector for derived state
const isAuthenticated = useSessionStore((state) => state.user !== null);

// ❌ Wrong — re-renders on ANY store change
const { user } = useSessionStore();
```

For multiple values:

```tsx
import { useShallow } from 'zustand/react/shallow';

const { user, isAuthenticated } = useSessionStore(
  useShallow((state) => ({ user: state.user, isAuthenticated: state.user !== null })),
);
```

## Actions Access (outside React)

Zustand actions can be called from non-component code via the store's `getState()`:

```typescript
// In a router guard, axios interceptor, etc.:
useSessionStore.getState().clearSession();
```

## Middleware

Common middleware:
- `devtools` — Redux DevTools integration (development)
- `persist` — localStorage / sessionStorage persistence
- `immer` — Immer-style mutation syntax inside actions
- `subscribeWithSelector` — selective subscriptions outside React

Add what the project needs; don't over-include.

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{name}Store.ts` (camelCase) | `sessionStore.ts`, `notificationStore.ts` |
| Location | `src/stores/` (global) | not in modules |
| Hook | `use{Name}Store` | `useSessionStore` |

## Server State — Use TanStack Query, NOT Zustand

A common anti-pattern is putting fetched data into Zustand. Don't. TanStack Query manages server state better (caching, invalidation, stale-while-revalidate, dedup).

Zustand is for **client state**: UI flags, user preferences, current session info, optimistic local state.

TanStack Query is for **server state**: data fetched from APIs.

If a store action also needs to fetch (like `fetchSession` above), it's fine — but for general list/detail fetches, prefer custom hooks wrapping TanStack Query.

## Key Points

- Zustand is the de-facto modern React state lib — use it if the project uses it
- Always select narrow slices to avoid unnecessary re-renders
- Use `useShallow` for multi-value selections
- Stores live in `src/stores/`, not in modules
- Use middleware sparingly — only what you need
- Server data goes in TanStack Query, NOT Zustand
- See SERVICE-002 for accessing services from store actions
