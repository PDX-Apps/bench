# ROUTE-002-route-constants

## Pattern

Each module declares route name constants in `src/modules/{Name}/router/constants.ts` as an `as const` object. These are used as `id` in route definitions and as stable references in navigation code.

## Structure

```typescript
// src/modules/Bill/router/constants.ts

export const BillRoutes = {
  LIST:   'bill.list',
  DETAIL: 'bill.detail',
  CREATE: 'bill.create',
  EDIT:   'bill.edit',
} as const;

export type BillRouteId = typeof BillRoutes[keyof typeof BillRoutes];
```

## Usage in Routes

```typescript
import { BillRoutes } from './constants';

const routes: RouteObject[] = [
  { id: BillRoutes.LIST, path: '/bills', element: <BillsPage /> },
  { id: BillRoutes.DETAIL, path: '/bills/:id', element: <BillPage /> },
];
```

## Usage in Navigation

If the project has a `pathFor()` helper (see ROUTE-001), use it:

```tsx
import { useNavigate } from 'react-router-dom';
import { pathFor } from 'src/router/helpers';
import { BillRoutes } from '../router/constants';

const navigate = useNavigate();
navigate(pathFor(BillRoutes.DETAIL, { id: bill.id }));
```

Otherwise direct path strings, but always derive them from constants where possible:

```tsx
navigate(`/bills/${bill.id}`);
```

## Naming Convention

Values: `{module}.{name}` lowercase dotted

```typescript
export const BillRoutes = {
  LIST:   'bill.list',
  DETAIL: 'bill.detail',
  CREATE: 'bill.create',
};
```

Keys: `UPPER_SNAKE_CASE` constants (LIST, DETAIL, CREATE).

## Why `as const`

```typescript
// ✅ as const — literal string union type
export const BillRoutes = { LIST: 'bill.list' } as const;
// typeof BillRoutes.LIST is 'bill.list' (the literal)

// ❌ Plain object
export const BillRoutes = { LIST: 'bill.list' };
// typeof BillRoutes.LIST is just `string` — loses the literal
```

The `as const` gives you exhaustive type-checking when matching on route IDs.

## Why values look like i18n keys (`bill.list`)

The convention mirrors i18n key shape so breadcrumb labels can reuse the same path:

```typescript
// In route handle
handle: {
  breadcrumb: { label: `${BillRoutes.LIST}.breadcrumb` },
}

// In translations
'bill.list.breadcrumb': 'Bills'
```

## Key Points

- One constants file per module's router
- `as const` object, NOT TypeScript `enum`
- Values: dotted lowercase `{module}.{name}`
- Keys: UPPER_SNAKE_CASE
- Used as `id` on route definitions
- See ROUTE-001 for route definitions
