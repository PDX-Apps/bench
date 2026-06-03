# HOOK-001-conventions

## Pattern

Custom React hooks are reusable functions starting with `use*` that encapsulate logic, state, or lifecycle. Use a hook when the same logic appears in 3+ components.

## Structure

```typescript
import { useState, useEffect, useCallback, useMemo } from 'react';
import { useLocation } from 'react-router-dom';
import { BillService } from 'src/modules/Bill/services/BillService';
import type { Bill, BillSummary } from 'src/modules/Bill/models';

/**
 * Bill summary hook
 *
 * Returns a reactive summary of the current user's bills with loading state.
 */
export function useBillSummary(): {
  summary: BillSummary;
  refresh: () => Promise<void>;
  isLoading: boolean;
} {
  const [bills, setBills] = useState<Bill[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const refresh = useCallback(async () => {
    setIsLoading(true);
    try {
      setBills(await BillService.list());
    } finally {
      setIsLoading(false);
    }
  }, []);

  const summary = useMemo<BillSummary>(() => ({
    total: bills.length,
    overdue: bills.filter((b) => b.isOverdue).length,
    paid: bills.filter((b) => b.isPaid).length,
  }), [bills]);

  return { summary, refresh, isLoading };
}
```

## Naming

- File: `use{Name}.ts` (camelCase, matches the function)
- Function: `use{Name}` (named export, NOT default)
- One hook per file is the strong convention

## Location

| Scope | Location |
|-------|----------|
| Module-specific hook | `src/modules/{Module}/hooks/use{Name}.ts` |
| Cross-module / shared | `src/hooks/use{Name}.ts` |

## Return Pattern

Return a typed object — not a tuple, not destructured primitives:

```typescript
// ✅ Right — object with named properties
return { summary, refresh, isLoading };

// ❌ Wrong — array tuple (consumers can't tell what's what without docs)
return [summary, refresh, isLoading];
```

Exception: hooks that mirror React's built-in `[value, setter]` shape (e.g., `useToggle(): [boolean, () => void]`) — that's idiomatic.

## What Belongs in a Hook

- ✅ Reactive state with derived values (`useMemo`)
- ✅ Side effects with cleanup (`useEffect`)
- ✅ Event handlers stable across renders (`useCallback`)
- ✅ Subscriptions to external sources (`useSyncExternalStore`)
- ✅ Composition of other hooks

## What Does NOT Belong

- ❌ Pure utility functions (no state, no effects) — put in `utils/` instead
- ❌ One-off logic used in only 1-2 components — keep inline
- ❌ Side effects without cleanup — hooks that allocate must release in `useEffect`'s cleanup

## Hooks That Use Other Hooks

Compose freely:

```typescript
export function useBillsForCurrentHousehold() {
  const { householdId } = useCurrentHousehold();
  const query = useQuery({
    queryKey: ['bills', householdId],
    queryFn: () => BillService.listForHousehold(householdId),
  });
  return { bills: query.data ?? [], isLoading: query.isPending };
}
```

## Rules of Hooks

Follow React's rules of hooks:
1. Call hooks at the top level only — never inside loops, conditions, or nested functions
2. Call hooks from React function components or other custom hooks — not from regular JS functions

Use `eslint-plugin-react-hooks` to enforce.

## Key Points

- Hooks are functions named `use{Name}` returning a typed object
- Live in `src/modules/{Module}/hooks/` (or `src/hooks/` if shared)
- Return an object with named properties — exception for value/setter pairs
- Always declare the return type
- Pure utilities without state/effects belong in `utils/`, not hooks
- See HOOK-002 for async-work patterns
