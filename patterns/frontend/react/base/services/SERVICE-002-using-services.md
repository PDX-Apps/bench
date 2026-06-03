# SERVICE-002-using-services

## Pattern

How components, hooks, and stores consume service classes.

Since React services are typically static methods (no DI), consumers call them directly through the project's data-fetching helper (TanStack Query, SWR, or a custom hook). See HOOK-002 for the async-task pattern.

## In Components (via TanStack Query)

```tsx
import { useQuery } from '@tanstack/react-query';
import { BillService } from '../services/BillService';

function BillsPage() {
  const { data: bills = [], isPending, isError } = useQuery({
    queryKey: ['bills', 'list'],
    queryFn: () => BillService.list(),
  });

  if (isPending) return <Skeleton />;
  if (isError) return <ErrorBanner />;
  return <BillList bills={bills} />;
}
```

## In Custom Hooks

Wrap services in custom hooks for reusability:

```tsx
// src/modules/Bill/hooks/useBills.ts
import { useQuery } from '@tanstack/react-query';
import { BillService } from '../services/BillService';

export function useBills() {
  return useQuery({
    queryKey: ['bills', 'list'],
    queryFn: () => BillService.list(),
  });
}

// In a component:
const { data, isPending } = useBills();
```

## Inside Mutations

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { BillService } from '../services/BillService';

export function useCreateBill() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateBillPayload) => BillService.create(payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['bills'] }),
  });
}
```

## Inside Zustand Stores

Services are imported directly into store actions:

```typescript
import { create } from 'zustand';
import { AuthService } from '../services/AuthService';
import { User } from '../models/User';

interface SessionState {
  user: User | null;
  initialized: boolean;
  fetchSession: () => Promise<void>;
  clearSession: () => void;
}

export const useSessionStore = create<SessionState>((set) => ({
  user: null,
  initialized: false,
  fetchSession: async () => {
    const data = await AuthService.fetchSession();
    set({ user: data ? User.fromApi(data) : null, initialized: true });
  },
  clearSession: () => set({ user: null }),
}));
```

## Inside Other Services (composition)

If service A depends on service B, just call it:

```typescript
export class BillReminderService {
  static async dispatchOverdueReminders() {
    const bills = await BillService.list();
    const overdue = bills.filter((b) => b.isOverdue);
    await Promise.all(overdue.map((b) => NotificationService.send(b)));
  }
}
```

No DI ceremony — services are static, just import and call.

## Anti-Patterns

```typescript
// ❌ Calling services directly in component body (fires every render)
function BillsPage() {
  const bills = BillService.list();  // promise — not even awaitable
  ...
}

// ❌ useState + useEffect for every fetch (re-implements TanStack Query badly)
const [bills, setBills] = useState([]);
useEffect(() => { BillService.list().then(setBills); }, []);

// ✅ Use the project's data-fetching helper
const { data: bills } = useBills();  // wraps TanStack Query
```

## Key Points

- Services are static — import and call directly
- Use TanStack Query (or project equivalent) to manage the async lifecycle
- Wrap service calls in custom hooks (`useBills`, `useCreateBill`) for reusability + cleaner component code
- Stores import services into their actions
- See SERVICE-001 for defining service classes
- See HOOK-002 for the async-task pattern
