# Hooks — conventions

Custom hooks extract reusable stateful logic from components — React's primary reuse mechanism.

## When

- Logic used by 2+ components, or one complex component you want to test in isolation.
- Anything stateful: a toggle, a debounced value, an event subscription, a media query.
- **Server state is NOT a plain hook** — use a query hook.
- **Pure, non-reactive helpers** (`formatDate`) are `utils/`, not hooks.

## Shape — `use*`, return a typed tuple or object

```ts
// hooks/useDisclosure.ts
import { useCallback, useState } from 'react'

export function useDisclosure(initial = false) {
  const [isOpen, setIsOpen] = useState(initial)

  const open = useCallback(() => setIsOpen(true), [])
  const close = useCallback(() => setIsOpen(false), [])
  const toggle = useCallback(() => setIsOpen((v) => !v), [])

  return { isOpen, open, close, toggle }
}
```

## Conventions

- **`use` prefix** (so the linter enforces the Rules of Hooks). File name = export name.
- **Call hooks at the top level** of the hook — never conditionally.
- **Stabilize callbacks** with `useCallback` and memos with `useMemo` when they're dependencies or passed to memoized children; keep dependency arrays correct.
- **Clean up** in `useEffect`'s return (subscriptions, timers, observers).
- **Return an object** (named fields) for 3+ values, a tuple for a clear 2-value pair (`[value, setValue]`).
- **One concern per hook**; compose small hooks.

## Don't

- Don't put server-state caching here — handle it in a query composable/hook instead.
- Don't call hooks conditionally, in loops, or outside React functions.
- Don't create a hook for a pure function — that's a util.
