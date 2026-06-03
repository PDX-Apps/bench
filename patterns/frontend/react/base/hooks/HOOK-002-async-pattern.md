# HOOK-002-async-pattern

## Pattern

Async work in components needs a consistent shape: loading state, captured errors, success/error notifications, and reset between calls. The de-facto React solution is **TanStack Query** (`@tanstack/react-query`), but the same shape can be built manually for projects that don't use it.

## Why a query/mutation helper (not raw async/await + useState)

Raw async/await inside `useEffect` leaves you re-implementing:

- Loading state (`isPending` flag + setters)
- Error capture
- Cache invalidation between renders
- Cancellation on unmount
- Retry logic
- Deduplication of concurrent requests

TanStack Query handles all of these. If the project uses something else (SWR, custom hooks, RTK Query), follow that convention.

## Discover the project's helper

Before writing async code, check:

```bash
grep -rh "useQuery\|useMutation\|useSWR\|useAsyncState" src/hooks/ src/modules/ 2>/dev/null | head
ls src/lib/queryClient* 2>/dev/null
```

## TanStack Query — queries (read)

```tsx
import { useQuery } from '@tanstack/react-query';
import { BillService } from 'src/modules/Bill/services/BillService';

export function useBillsQuery() {
  return useQuery({
    queryKey: ['bills', 'list'],
    queryFn: () => BillService.list(),
  });
}

// In a component:
function BillsPage() {
  const { data: bills = [], isPending, isError, refetch } = useBillsQuery();

  if (isPending) return <Skeleton />;
  if (isError) return <ErrorBanner onRetry={refetch} />;
  if (bills.length === 0) return <EmptyState />;

  return <BillList bills={bills} />;
}
```

## TanStack Query — mutations (write)

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';  // or whatever toast lib the project uses
import { BillService } from '../services/BillService';

export function useCreateBillMutation() {
  const queryClient = useQueryClient();
  const { t } = useTranslation();

  return useMutation({
    mutationFn: (payload: CreateBillPayload) => BillService.create(payload),
    onSuccess: () => {
      toast.success(t('bill.notifications.success.created'));
      queryClient.invalidateQueries({ queryKey: ['bills'] });
    },
    onError: () => {
      toast.error(t('bill.notifications.errors.createFailed'));
    },
  });
}
```

In a component:

```tsx
const createBill = useCreateBillMutation();

async function handleSubmit(data: BillFormData) {
  const bill = await createBill.mutateAsync(data);
  // bill is the resolved value; on error, mutateAsync throws
  onSuccess?.(bill);
}

// Use createBill.isPending for button loading, createBill.error for error display
```

## Reactive properties

| Property | Type | Description |
|----------|------|-------------|
| `data` | `T \| undefined` | The resolved value (mutations: latest result) |
| `isPending` | `boolean` | True while the request is in flight |
| `isError` | `boolean` | True if the last attempt errored |
| `error` | `unknown` | The error object (when isError) |
| `refetch` (queries) | `() => Promise<void>` | Manually re-run |
| `mutate` / `mutateAsync` (mutations) | `(input) => void / Promise<T>` | Trigger |

## Query keys (cache identity)

Structure query keys as arrays from general → specific:

```typescript
['bills']                      // all bill queries
['bills', 'list']              // bill list
['bills', 'detail', billId]    // single bill
['bills', 'list', { householdId }]  // filtered list
```

Invalidating `['bills']` invalidates all sub-queries.

## Inline fallback — when the project has no TanStack Query

If no shared helper exists, reimplement the basic shape with `useState` + `useEffect`:

```typescript
import { useState, useEffect } from 'react';

function useBills() {
  const [bills, setBills] = useState<Bill[]>([]);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<unknown>(null);

  useEffect(() => {
    let cancelled = false;
    setIsPending(true);
    setError(null);
    BillService.list()
      .then((data) => { if (!cancelled) setBills(data); })
      .catch((e) => { if (!cancelled) setError(e); })
      .finally(() => { if (!cancelled) setIsPending(false); });
    return () => { cancelled = true; };
  }, []);

  return { bills, isPending, error };
}
```

Consider extracting this shape into a project-wide helper if used in 3+ places.

## Anti-Patterns

```tsx
// ❌ Calling service.list() directly in render — fires every render
function BillsPage() {
  const bills = await BillService.list();  // even ignoring await, this re-fetches forever
  ...
}

// ❌ Not handling cleanup — setting state after unmount
useEffect(() => {
  fetch(...).then(setBills);  // setBills may fire after unmount
}, []);

// ✅ With TanStack Query, cleanup + dedup are handled
const { data } = useQuery({ queryKey: ['bills'], queryFn: BillService.list });
```

## Key Points

- TanStack Query is the de-facto React async pattern — use it if the project does
- For projects without it: handle `isPending`, `error`, cleanup on unmount manually
- Structure query keys array-style for hierarchical invalidation
- Mutations + queries are the two primitives — read vs write
- See COMPONENT-002 for forms (which use mutations), COMPONENT-003 for dialogs
