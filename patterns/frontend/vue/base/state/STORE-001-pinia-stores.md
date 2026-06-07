# Pinia stores

Global/shared **client state** with Pinia. Use the **setup-store** syntax (the modern default).

## When

- State shared across unrelated components: the current user/session, UI preferences (theme, sidebar), a cross-page wizard.
- **Not for server data** — cached API data belongs in query composables ([QUERY-001](../data/QUERY-001-tanstack-query.md)), not a hand-rolled store. Use Pinia for *client* state.

## Shape — setup store

```ts
// stores/session.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@/types/user'

export const useSessionStore = defineStore('session', () => {
  // state
  const user = ref<User | null>(null)

  // getters
  const isAuthenticated = computed(() => user.value !== null)

  // actions
  function setUser(next: User | null) {
    user.value = next
  }
  function clear() {
    user.value = null
  }

  return { user, isAuthenticated, setUser, clear }
})
```

Usage (keep reactivity with `storeToRefs`):

```ts
import { storeToRefs } from 'pinia'
const session = useSessionStore()
const { user, isAuthenticated } = storeToRefs(session) // refs stay reactive
session.setUser(loaded)                                 // call actions directly
```

## Conventions

- **`use{Name}Store`** export, `defineStore('{name}', () => {…})` with a string id.
- **`ref`/`reactive` = state, `computed` = getters, functions = actions.** Return everything you want public.
- **Destructure with `storeToRefs`** for state/getters (plain destructuring loses reactivity); call actions off the store object.
- **Keep stores small and cohesive** — one domain each (`session`, `cart`, `ui`). Don't build one mega-store.
- **Persistence** (localStorage, etc.) via a Pinia plugin if needed — keep it out of component code.

## Don't

- Don't use the options-store form (`{ state, getters, actions }`) for new stores unless the project already does — match the project, but setup stores are the base default.
- Don't cache server responses in a store — that's a query's job (caching, invalidation, refetch).
- Don't mutate state outside actions.

## See also

- [QUERY-001](../data/QUERY-001-tanstack-query.md) (server state) · [COMPOSABLE-001](../composables/COMPOSABLE-001-conventions.md)
