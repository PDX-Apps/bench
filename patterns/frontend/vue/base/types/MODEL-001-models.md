# MODEL-001-models

## Pattern

Models are TypeScript classes that wrap API data with computed getters, domain methods, and a static `fromApi()` factory. Each model file exports both the class AND its data interface (`I{Name}`).

## Structure

```typescript
import type { IBillMember } from './BillMember';
import { BillMember } from './BillMember';

/**
 * Bill data shape returned from the API
 */
export interface IBill {
  id: string;
  name: string;
  amount: number;
  currency: string;
  status: 'unpaid' | 'partial' | 'paid' | 'skipped';
  next_due_date: string;
  created_by: string;
  members?: IBillMember[];
  created_at: string;
  updated_at: string;
}

/**
 * Bill Model
 *
 * Represents a bill (either personal or household)
 */
export class Bill implements IBill {
  id: string;
  name: string;
  amount: number;
  currency: string;
  status: IBill['status'];
  next_due_date: string;
  created_by: string;
  members?: BillMember[];
  created_at: string;
  updated_at: string;

  constructor(data: IBill) {
    this.id = data.id;
    this.name = data.name;
    this.amount = data.amount;
    this.currency = data.currency;
    this.status = data.status;
    this.next_due_date = data.next_due_date;
    this.created_by = data.created_by;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;

    // Convert nested objects to model instances
    if (data.members) {
      this.members = data.members.map((m) => new BillMember(m));
    }
  }

  /**
   * Create a Bill instance from API data.
   * Use `this: void` so this method is callable as a free function:
   *   bills.map(Bill.fromApi)
   */
  static fromApi(this: void, data: IBill): Bill {
    return new Bill(data);
  }

  // ==================== Computed Getters ====================

  get isPaid(): boolean {
    return this.status === 'paid';
  }

  get isOverdue(): boolean {
    return !this.isPaid && new Date(this.next_due_date) < new Date();
  }

  // ==================== Domain Methods ====================

  canEditBy(userId: string): boolean {
    return this.created_by === userId;
  }

  // ==================== Static Utilities ====================

  static calculateTotalAssigned(members: BillMember[]): number {
    return members.reduce((sum, m) => sum + (m.split_amount ?? 0), 0);
  }
}
```

## Required Conventions

1. **Two exports per file**: `interface I{Name}` (data shape) AND `class {Name}` (rich object)
2. **Class implements its interface**: `class Bill implements IBill { ... }`
3. **Constructor takes the interface data**: maps fields, converts nested arrays to model instances
4. **`static fromApi(this: void, data: I{Name}): {Name}`** — the canonical factory; usable as map callback
5. **Computed values as getters**: `get isPaid()`, `get isOverdue()`
6. **Domain methods**: business logic + permission checks (`canEditBy(userId)`)
7. **Static utilities**: pure functions on the model (`Bill.calculateTotalAssigned(members)`)

## The `this: void` Trick

`static fromApi(this: void, data)` makes the method callable without `this` binding:

```typescript
// Without `this: void`, this would fail:
bills.map(Bill.fromApi);  // would lose `this`

// With `this: void`, it works:
bills.map(Bill.fromApi);  // ✅ identical to bills.map(b => Bill.fromApi(b))
```

## Section Organization

Inside the class, group with `// ====` separators:

```typescript
// ==================== Computed Getters ====================
// ==================== Domain Methods ====================
// ==================== Static Utilities ====================
```

## Nested Models

When a model contains nested objects (e.g., Bill has BillMembers), convert them in the constructor:

```typescript
constructor(data: IBill) {
  // ... primitive fields
  if (data.members) {
    this.members = data.members.map((m) => new BillMember(m));
  }
}
```

The nested model also has its own `I{Name}` interface and `fromApi()`.

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{Name}.ts` (PascalCase) | `Bill.ts`, `BillMember.ts` |
| Location | `src/modules/{Module}/models/` | `Bill/models/Bill.ts` |
| Interface | `I{Name}` | `IBill`, `IBillMember` |
| Class | `{Name}` | `Bill`, `BillMember` |
| Barrel export | `models/index.ts` re-exports all | `export { Bill } from './Bill'` |

Top-level shared models (used cross-module) live in `src/models/` (e.g., `User.ts`).

## Key Points

- Two exports: `I{Name}` interface + `{Name}` class
- Class implements interface
- Constructor maps from interface data, converts nested arrays
- `static fromApi(this: void, data)` — canonical factory
- Getters for computed values, methods for domain logic
- Use `// ====` separator comments by section
- See SERVICE-001 — services always return models via `Model.fromApi()`
- See TYPE-001 for related Payload/Response types
