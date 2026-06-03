# COMPOSABLE-001-conventions

## Pattern

Composables are reusable Vue functions starting with `use*` that encapsulate logic, state, or lifecycle hooks. Use composables when the same logic appears in 3+ components.

## Structure

```typescript
import { computed, type ComputedRef, ref, type Ref } from 'vue';
import { useRoute } from 'vue-router';
import { BillService } from 'src/modules/Bill/services/BillService';
import type { Bill, BillSummary } from 'src/modules/Bill/models';

/**
 * Bill summary composable
 *
 * Provides a reactive summary of the current user's bills.
 * Handles loading state and error reporting.
 */
export function useBillSummary(): {
  summary: ComputedRef<BillSummary>;
  refresh: () => Promise<void>;
  isLoading: Ref<boolean>;
} {
  const bills = ref<Bill[]>([]);
  const isLoading = ref(false);

  async function refresh(): Promise<void> {
    isLoading.value = true;
    try {
      bills.value = await BillService.list();
    } finally {
      isLoading.value = false;
    }
  }

  const summary = computed<BillSummary>(() => ({
    total: bills.value.length,
    overdue: bills.value.filter((b) => b.isOverdue).length,
    paid: bills.value.filter((b) => b.isPaid).length,
  }));

  return { summary, refresh, isLoading };
}
```

## Naming

- File: `use{Name}.ts` (camelCase)
- Function: `use{Name}` matching the file
- One composable per file (named export, not default)

## Location

| Scope | Location |
|-------|----------|
| Module-specific composable | `src/modules/{Module}/composables/use{Name}.ts` |
| Cross-module / shared | `src/composables/use{Name}.ts` or `src/modules/Core/composables/use{Name}.ts` — match project convention |

## Return Pattern

Return a typed object — not a tuple, not destructured primitives:

```typescript
// ✅ Right — object with named properties
return { summary, refresh, isLoading };

// ❌ Wrong — array destructure (consumers can't tell what's what)
return [summary, refresh, isLoading];
```

Always declare the return type explicitly. Helps IDE inference and serves as inline documentation.

## What Belongs in a Composable

- ✅ Reactive state with computed derivations
- ✅ Logic that interacts with services + UI state together
- ✅ Lifecycle hooks (`onMounted`, `onUnmounted`)
- ✅ Watchers across reactive deps
- ✅ Provide/inject for cross-component data passing

## What Does NOT Belong

- ❌ Pure utility functions (no reactivity) — put in `utils/` instead
- ❌ One-off logic used in only 1-2 components — keep inline
- ❌ Side effects without cleanup — composables that allocate must release in `onUnmounted`

## Provide/Inject Pattern

Composables can use `provide`/`inject` to pass data through the component tree:

```typescript
const KEY = Symbol('my-context');

export function provideMyContext(value: Ref<MyType>) {
  provide(KEY, value);
}

export function useMyContext(): Ref<MyType | undefined> {
  return inject(KEY, ref(undefined));
}
```

## Composables That Use Other Composables

Compose freely — composables are just functions:

```typescript
export function useBillsForCurrentHousehold() {
  const { householdId } = useCurrentHousehold();   // another composable
  // ... build on top
}
```

## Module Augmentation Pattern

Composables that interact with router meta can augment the route types:

```typescript
declare module 'vue-router' {
  interface RouteMeta {
    breadcrumb?: BreadcrumbMeta;
  }
}
```

This makes the meta property type-safe project-wide.

## Key Points

- Composables are functions named `use{Name}` returning a typed object
- Live in `src/modules/{Module}/composables/` (or `src/composables/` if shared)
- Return an object with named properties — never a tuple
- Always declare the return type
- Use `provide`/`inject` for cross-component data sharing
- Pure utilities without reactivity belong in `utils/`, not `composables/`
- See COMPOSABLE-002 for the async-work composable pattern
