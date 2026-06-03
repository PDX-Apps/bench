# MODEL-001-models

## Pattern

Model classes wrap API response data with typed fields, computed getters, domain methods, and a static factory. Same pattern as Vue — class + `I{Name}` interface + `static fromApi(this: void, data)` factory.

## Structure

```typescript
import { BillMember, type IBillMember } from './BillMember';

export interface IBill {
  id: string;
  name: string;
  amount: number;
  status: 'unpaid' | 'paid' | 'partial' | 'skipped';
  dueDate: string;  // ISO date
  members?: IBillMember[];
  createdAt: string;
  updatedAt: string;
}

export class Bill implements IBill {
  id!: string;
  name!: string;
  amount!: number;
  status!: 'unpaid' | 'paid' | 'partial' | 'skipped';
  dueDate!: string;
  members?: BillMember[];
  createdAt!: string;
  updatedAt!: string;

  constructor(data: IBill) {
    Object.assign(this, data);
    if (data.members) {
      this.members = data.members.map((m) => BillMember.fromApi(m));
    }
  }

  // ==================== Computed Getters ====================

  get isPaid(): boolean {
    return this.status === 'paid';
  }

  get isOverdue(): boolean {
    if (this.isPaid) return false;
    return new Date(this.dueDate) < new Date();
  }

  get totalApprovedSplit(): number {
    return (this.members ?? [])
      .filter((m) => m.status === 'approved')
      .reduce((sum, m) => sum + m.amount, 0);
  }

  // ==================== Domain Methods ====================

  canEditBy(userId: string): boolean {
    return this.members?.some((m) => m.userId === userId && m.role === 'owner') ?? false;
  }

  // ==================== Factory ====================

  /**
   * Map API response data to a Bill instance.
   * `this: void` so the function works without `this` binding (enables `.map(Bill.fromApi)`).
   */
  static fromApi(this: void, data: IBill): Bill {
    return new Bill(data);
  }
}
```

## Why a class (not a plain interface)?

Plain interfaces give you typed data but no derived methods. Classes let you:

- Define computed getters (`isOverdue`, `isPaid`) that consumers don't have to re-derive
- Centralize domain methods (`canEditBy`, `isCreatedBy`) so logic lives with the data
- Convert nested data in the constructor (e.g., `members` → `BillMember[]` instances)

If the project prefers plain interfaces + utility functions, follow that — but the class pattern scales better for non-trivial domains.

## Factory pattern (`static fromApi(this: void, data)`)

The `this: void` annotation lets the function work standalone:

```typescript
const bills: Bill[] = response.data.map(Bill.fromApi);  // works — no this binding needed
```

Without it, you'd need `data.map((b) => Bill.fromApi(b))`.

## Nested Models

If a model has nested models (Bill → BillMember[]), convert them in the constructor:

```typescript
constructor(data: IBill) {
  Object.assign(this, data);
  if (data.members) {
    this.members = data.members.map((m) => BillMember.fromApi(m));
  }
}
```

This ensures consumers always get class instances (with their own getters/methods), not raw JSON.

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{Name}.ts` (PascalCase) | `Bill.ts` |
| Interface | `I{Name}` | `IBill` |
| Class | `{Name}` | `Bill` |
| Top-level (User) | `src/models/` | `src/models/User.ts` |
| Module-local | `src/modules/{Module}/models/` | `src/modules/Bill/models/Bill.ts` |
| Barrel | `models/index.ts` | re-exports |

## Section Comments

Group class members by purpose:

```typescript
// ==================== Computed Getters ====================
// ==================== Domain Methods ====================
// ==================== Static Utilities ====================
// ==================== Factory ====================
```

## Key Points

- Class + `I{Name}` interface + static `fromApi(this: void, data)` factory
- Computed getters for derived state
- Domain methods for business logic
- Nested models converted in constructor
- Section comments for organization
- Barrel exports from `models/index.ts`
