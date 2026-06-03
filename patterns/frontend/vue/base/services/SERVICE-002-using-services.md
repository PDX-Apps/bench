# SERVICE-002-using-services

## Pattern

How components, stores, and composables consume service classes.

The exact mechanism depends on whether the project uses dependency injection (DI), a singleton container, or plain imports. Generic Vue projects typically use plain imports; framework wrappers layer DI on top.

## Plain-import pattern (default)

```typescript
import { BillService } from '../services/BillService';

// In setup() / <script setup>:
const bills = await BillService.list();
```

If service methods are static, no instantiation is needed. If the service is a class with state, instantiate once per consumer (typically at module scope) or via the project's existing helper.

## Singleton container pattern

If the project provides a service container (e.g., a `useServices()` composable, or a custom DI helper), follow that convention:

```typescript
import { useServices } from 'src/services';
import { BillService } from '../services/BillService';

const { get } = useServices();
const billService = get(BillService);
```

Discover the project's mechanism by reading at least one existing component or composable that consumes a service. Don't introduce a new pattern.

## Inside Pinia Stores

In a Pinia store action, import the service and call it. If the project uses a DI helper, prefer that:

```typescript
import { AuthService } from '../services/AuthService';

actions: {
  async fetchSession() {
    const userData = await AuthService.fetchSession();
    this.user = userData;
  },
},
```

## Inside Composables

Composables run in setup context, so they can use any composable-style helpers the project provides:

```typescript
import { ref } from 'vue';
import { BillService } from 'src/modules/Bill/services/BillService';

export function useBillSummary() {
  const summary = ref(null);
  const loading = ref(false);

  async function refresh() {
    loading.value = true;
    try {
      summary.value = await BillService.list();
    } finally {
      loading.value = false;
    }
  }

  return { summary, loading, refresh };
}
```

## Inside Other Services (composition)

If service A depends on service B, compose at construction. The exact mechanism depends on whether the project uses DI — discover from existing services.

## Anti-Patterns

```typescript
// ❌ Don't bypass the project's existing service-access convention
//   If sibling components use a container/DI helper, follow that.
//   If they use plain imports, follow that.

// ❌ Don't access services outside setup() / actions / composable scope
//   The project's helpers (if any) typically require a Vue setup context.

// ❌ Don't `new` a service that the project expects to be a singleton
```

## Key Points

- Discover the project's service-access convention from sibling consumers (plain import, DI helper, singleton container)
- In stores, import services directly or use the project's helper
- In composables, use the same approach as components (they share setup context)
- NEVER introduce a new service-access mechanism — follow what the project has
- See SERVICE-001 for defining service classes
- See COMPOSABLE-001 for composable patterns
