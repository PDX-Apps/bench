# COMPONENT-001-conventions

## Pattern

React functional components written in TypeScript. Components live under `src/modules/{Name}/components/` (or whatever feature-folder convention the project uses) organized by semantic folders.

## Folder Conventions

| Folder | Purpose | Example |
|--------|---------|---------|
| `Cards/` | Display a single resource summary | `BillCard.tsx` |
| `Dialogs/` | Modal dialogs (create/edit, confirm) | `BillFormDialog.tsx` |
| `Forms/` | Form components (often used inside Dialogs) | `BillForm.tsx` |
| `Inputs/` | Reusable input wrappers | `EmailInput.tsx` |
| `Sections/` | Page sections | `HeroSection.tsx` |
| `Common/` | Cross-cutting utilities | `TaskErrors.tsx` |

## Structure

```tsx
import { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import type { Bill } from '../../types/bill.types';

interface BillCardProps {
  bill: Bill;
  expandable?: boolean;
  onClick?: (bill: Bill) => void;
  onEdit?: (bill: Bill) => void;
}

export function BillCard({ bill, expandable = false, onClick, onEdit }: BillCardProps) {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(false);

  const formattedAmount = useMemo(
    () => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(bill.amount),
    [bill.amount],
  );

  return (
    <article className="bill-card" onClick={() => onClick?.(bill)} data-testid="bill-card">
      <h3 className="text-lg font-semibold">{bill.name}</h3>
      <p className="text-sm">{formattedAmount}</p>
      {expandable && (
        <button onClick={(e) => { e.stopPropagation(); setExpanded(!expanded); }}>
          {expanded ? t('common.collapse') : t('common.expand')}
        </button>
      )}
    </article>
  );
}
```

If the project uses a UI library (Radix, MUI, Chakra, headless UI, shadcn/ui), substitute its primitives. Follow what sibling components do.

## Conventions

- **Functional components only** — no class components
- **TypeScript** — always; props typed via interface
- **Named exports** — `export function ComponentName(...)`, never default exports (better for refactoring/discovery)
- **Hooks order** — useState → useMemo / useCallback → custom hooks → useEffect (consistent ordering aids readability)
- **Props destructured in signature** with defaults inline
- **Optional callbacks** — `onClick?: (x: T) => void`, use optional chaining when calling (`onClick?.(x)`)
- **`data-testid`** on interactive elements for testability
- **i18n** via `useTranslation()` from react-i18next (or project's helper)

## Sizing Guidance

- Components > 250 lines → split into sub-components
- Repeated logic in 3+ components → extract to custom hook (see HOOK-001)
- Pure presentation: no service calls, just props in, callbacks out
- "Smart" components (data-fetching, mutations): use the project's async-task pattern (HOOK-002) and services

## Naming

- PascalCase filenames matching the exported component: `BillCard.tsx`, `MemberSplitInput.tsx`
- File name matches primary export
- Variants suffix with the variant: `BillForm.tsx`, `HouseholdBillForm.tsx`

## Key Points

- One component per file, named export matching filename
- Props typed via interface
- Hooks in consistent order (state → derived → custom → effects)
- Use project's UI library conventions; don't introduce a new one
- See COMPONENT-002 for forms, COMPONENT-003 for dialogs/modals
