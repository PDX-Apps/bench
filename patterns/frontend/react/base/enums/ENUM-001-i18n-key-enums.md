# ENUM-001-i18n-key-enums

## Pattern

When an enum represents user-facing states (bill status, member role, notification type), make each enum value an **i18n translation key**. Components display the value through `t()`, automatically getting the right translation.

## Structure

```typescript
// src/modules/Bill/enums/BillStatusEnum.ts

export const BillStatus = {
  UNPAID:  'bill.status.unpaid',
  PAID:    'bill.status.paid',
  PARTIAL: 'bill.status.partial',
  SKIPPED: 'bill.status.skipped',
} as const;

export type BillStatusKey = keyof typeof BillStatus;
export type BillStatusValue = typeof BillStatus[BillStatusKey];
```

## Translation File

```typescript
// src/modules/Bill/i18n/en-US/bill.ts
export default {
  status: {
    unpaid: 'Unpaid',
    paid: 'Paid',
    partial: 'Partially Paid',
    skipped: 'Skipped',
  },
};
```

## Usage

```tsx
import { useTranslation } from 'react-i18next';
import { BillStatus } from '../enums/BillStatusEnum';

function BillStatusBadge({ status }: { status: BillStatusValue }) {
  const { t } = useTranslation();
  return <span>{t(status)}</span>;
}

// Caller passes the enum value (which IS the i18n key):
<BillStatusBadge status={BillStatus.PAID} />
// Renders "Paid" (en-US) or "Pagado" (es-MX)
```

## Why values = i18n keys

Without this convention you'd write:

```tsx
{status === 'paid' && <span>{t('bill.status.paid')}</span>}
{status === 'unpaid' && <span>{t('bill.status.unpaid')}</span>}
// ...
```

With it, ONE `t(status)` call does the work.

## Mapping API status (string) to enum

API responses use lowercase string status (`'paid'`, `'unpaid'`). Models convert at the boundary:

```typescript
import { BillStatus } from '../enums/BillStatusEnum';

const statusMap: Record<string, BillStatusValue> = {
  unpaid: BillStatus.UNPAID,
  paid: BillStatus.PAID,
  partial: BillStatus.PARTIAL,
  skipped: BillStatus.SKIPPED,
};

// In the Bill model constructor:
this.status = statusMap[data.status] ?? BillStatus.UNPAID;
```

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{Name}Enum.ts` | `BillStatusEnum.ts` |
| Const | `{Name}` | `BillStatus` |
| Value type | `{Name}Value` | `BillStatusValue` |
| Key type | `{Name}Key` | `BillStatusKey` |
| Location | `src/modules/{Module}/enums/` | `Bill/enums/BillStatusEnum.ts` |

## Why `as const` (not `enum`)

TypeScript `enum` produces extra runtime code and has tricky semantics (numeric vs string, reverse mappings). `as const` objects are simpler and more idiomatic in modern TS:

```typescript
// ✅ Recommended
export const BillStatus = { PAID: 'bill.status.paid' } as const;

// ❌ Avoid
export enum BillStatus { PAID = 'bill.status.paid' }
```

## Key Points

- Enum values = i18n keys (full dotted path like `module.status.value`)
- Use `as const` objects, not `enum` keyword
- Map API string status → enum at the model boundary
- One `t(status)` call replaces N conditional renders
- See I18N-001 for the matching translation tree
