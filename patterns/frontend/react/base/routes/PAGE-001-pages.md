# PAGE-001-pages

## Pattern

Page components are route-level entry points. They live in `src/modules/{Name}/pages/` with the `*Page.tsx` suffix. Pages compose smaller components, fetch data via custom hooks (which wrap TanStack Query / services), and orchestrate user interactions.

## Structure

```tsx
import { useState, Suspense } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { BillCard } from '../components/Cards/BillCard';
import { BillFormDialog } from '../components/Dialogs/BillFormDialog';
import { BillService } from '../services/BillService';
import { BillRoutes } from '../router/constants';
import { pathFor } from 'src/router/helpers';
import type { Bill } from '../types/bill.types';
import { TaskErrors } from 'src/components/TaskErrors';

export default function BillsPage() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [dialogOpen, setDialogOpen] = useState(false);

  const { data: bills = [], isPending, isError, error, refetch } = useQuery({
    queryKey: ['bills', 'list'],
    queryFn: () => BillService.list(),
  });

  function handleCardClick(bill: Bill) {
    navigate(pathFor(BillRoutes.DETAIL, { id: bill.id }));
  }

  return (
    <div className="bill-list-page p-4 md:p-8">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('bill.pages.list.title')}</h1>
          <p className="text-gray-600">{t('bill.pages.list.subtitle')}</p>
        </div>
        <button onClick={() => setDialogOpen(true)} data-testid="bills-page-add">
          + Add
        </button>
      </header>

      {isError && <TaskErrors error={error} onRetry={refetch} />}

      {/* Loading skeleton */}
      {isPending && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => <div key={i} className="skeleton" />)}
        </div>
      )}

      {/* Empty state */}
      {!isPending && bills.length === 0 && (
        <div className="empty p-8 text-center">
          <p>{t('bill.pages.list.empty.title')}</p>
        </div>
      )}

      {/* Data */}
      {!isPending && bills.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {bills.map((bill) => (
            <BillCard key={bill.id} bill={bill} onClick={handleCardClick} />
          ))}
        </div>
      )}

      <BillFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        mode="create"
      />
    </div>
  );
}
```

If the project uses a UI library (MUI, Radix, Chakra), substitute its primitives. Discover from sibling pages.

## Page Lifecycle

1. **Mount** — TanStack Query auto-fetches via `useQuery`
2. **Pending state** — `isPending`, render skeleton
3. **Error state** — `isError`, render error UI with retry
4. **Empty state** — `data.length === 0`, render empty state
5. **Data state** — render the list/detail
6. **Mutations** — open dialogs, call services via `useMutation`, invalidate query keys on success

## Default vs Named Export

Pages are commonly **default-exported** because they're lazy-loaded via `lazy(() => import('./BillsPage'))`. Other components in the project should use named exports — pages are the exception for lazy compatibility.

## Conventions

- Suffix: `*Page.tsx` (`BillsPage.tsx`, `BillPage.tsx`, `HouseholdMembersPage.tsx`)
- **Default export** (for lazy loading)
- Page is the orchestrator — owns state for the route
- Use TanStack Query (or project equivalent) for data fetching
- Use `useNavigate()` for navigation, `useParams()` for URL params
- Navigate via route-id constants (`pathFor(BillRoutes.DETAIL, { id })`)
- i18n via `useTranslation()`

## Loading + Empty + Error States

Every page that fetches data should explicitly handle:
- **Loading** (`isPending`) — skeleton
- **Empty** (`data.length === 0`) — empty state with CTA
- **Data** — render list/items
- **Error** — error display with retry

## Page Sizing

- Pages > 300 lines → extract sections into `components/Sections/`
- Repeated data-fetching logic across pages → extract to custom hook

## Suspense Boundary

If the layout doesn't wrap `<Outlet />` in `<Suspense>`, pages should manage their own loading via TanStack Query's `isPending`. Either approach works — be consistent with the project.

## Key Points

- One Page per route, suffixed `*Page.tsx`, **default export**
- Pages own state and orchestrate; components present
- Use TanStack Query for data fetching (or project equivalent)
- Always handle loading + empty + error states explicitly
- Navigate via route-id constants
- See ROUTE-001 for route definitions, ROUTE-002 for route id constants
