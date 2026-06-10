# Composables — conventions

Reusable reactive logic extracted from components. The primary way to share stateful behaviour in Vue 3.

## When

- Logic used by 2+ components (or one complex component you want to test in isolation).
- Anything stateful + reactive: a toggle, a debounced value, a resize observer, a form helper.
- **Server state is NOT a plain composable** — use a query composable.
- **Pure, non-reactive helpers** (`formatDate`, `slugify`) are `utils/`, not composables.

## Shape — `use*` prefix, return a typed object

```ts
// composables/useDisclosure.ts
import { ref, readonly } from 'vue'

export function useDisclosure(initial = false) {
  const isOpen = ref(initial)

  function open() { isOpen.value = true }
  function close() { isOpen.value = false }
  function toggle() { isOpen.value = !isOpen.value }

  return {
    isOpen: readonly(isOpen),
    open,
    close,
    toggle,
  }
}
```

Usage:

```ts
const { isOpen, open, close } = useDisclosure()
```

## Conventions

- **`use` prefix**, camelCase file = export name (`useDisclosure.ts` → `useDisclosure`).
- **Accept arguments, return an object** of refs/computed/functions. Return `readonly()` refs the caller shouldn't mutate directly.
- **Set up and clean up** lifecycle inside the composable (`onMounted`/`onUnmounted`, `watch` with its stop handle) so callers don't have to.
- **Stay framework-pure** — no direct DOM assumptions beyond what you guard; accept element refs as args rather than querying the document.
- **One concern per composable.** Compose small ones rather than building a god-composable.
- **SSR-safe** if the project might use Nuxt — guard `window`/`document` access.

## Don't

- Don't put server-state caching here — handle it in a query composable/hook instead.
- Don't return a giant mutable object; expose intent (functions) over raw state where it matters.
- Don't create a composable for a pure function — that's a util.
