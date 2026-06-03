# STORE-001-pinia-stores

## Pattern

Pinia stores hold global reactive state shared across the app. Use the typed `defineStore` generic form for full TypeScript safety on state, getters, and actions.

## When to Use a Store

- ✅ State that survives across route changes (current user session, app-wide settings)
- ✅ State shared across unrelated components (notifications, modals, theme)
- ❌ Page-local state — use `ref()` in the Page
- ❌ Module-local state — use a composable
- ❌ Form state — use the form component's `ref()` + `defineModel`

## Structure

```typescript
import { acceptHMRUpdate, defineStore } from 'pinia';
import { AuthService } from '../services/AuthService';
import { User, type IUser } from '../models/User';

interface SessionState {
  user: User | null;
  initialized: boolean;
}

type SessionGetters = {
  isAuthenticated: (state: SessionState) => boolean;
  isInitialized: (state: SessionState) => boolean;
  getUser: (state: SessionState) => User | null;
};

interface SessionActions {
  setSession(data: IUser): void;
  clearSession(): void;
  fetchSession(): Promise<void>;
}

export const useSessionStore = defineStore<
  'session',
  SessionState,
  SessionGetters,
  SessionActions
>('session', {
  state: (): SessionState => ({
    user: null,
    initialized: false,
  }),

  getters: {
    isAuthenticated: (state) => state.user !== null,
    isInitialized: (state) => state.initialized,
    getUser: (state) => state.user,
  },

  actions: {
    setSession(data: IUser) {
      this.user = User.fromApi(data);
      this.initialized = true;
    },

    clearSession() {
      this.user = null;
    },

    async fetchSession() {
      if (this.initialized) return;
      const userData = await AuthService.fetchSession();
      if (userData) this.setSession(userData);
      else this.initialized = true;
    },
  },
});

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useSessionStore, import.meta.hot));
}
```

## Typing the Store

The 4 generics on `defineStore<...>` give full type safety:

1. **Store ID** (`'session'`) — the registered name
2. **State** (`SessionState`) — interface for state shape
3. **Getters** (`SessionGetters`) — type with `(state) => T` signatures
4. **Actions** (`SessionActions`) — interface with method signatures

`this` inside actions is correctly typed (state + getters + actions).

## Service Access in Actions

Import services directly, or use the project's existing helper (DI container, framework wrapper). Discover the convention from sibling stores.

If the project uses a framework wrapper, there may be a `this.$container` or similar exposed inside actions — follow that convention instead of plain imports.

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{name}Store.ts` (camelCase) | `sessionStore.ts`, `notificationStore.ts` |
| Location | `src/stores/` (global) | not in modules — stores are global |
| Composable | `use{Name}Store` | `useSessionStore` |
| Store ID | `'{name}'` (kebab if multi-word) | `'session'`, `'user-prefs'` |

## Usage in Components

```typescript
import { useSessionStore } from 'src/stores/sessionStore';
import { storeToRefs } from 'pinia';

const session = useSessionStore();

// Read reactive state directly
console.log(session.user);
if (session.isAuthenticated) { /* ... */ }

// For destructuring with reactivity preserved:
const { user, isAuthenticated } = storeToRefs(session);
```

Methods (actions) destructure normally — they don't need `storeToRefs`.

## HMR

When the project uses Vite, include the HMR block at the bottom — fast refresh during development:

```typescript
if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useSessionStore, import.meta.hot));
}
```

## Key Points

- Use the typed generic form: `defineStore<ID, State, Getters, Actions>(...)`
- State is a function returning the initial state
- Getters typed as `(state) => T`
- Actions typed via interface
- Service access in actions: follow project convention (import vs DI helper)
- Stores live in `src/stores/`, not in modules
- Use `storeToRefs(store)` when destructuring reactive state
- Always add HMR block at the bottom (Vite projects)
