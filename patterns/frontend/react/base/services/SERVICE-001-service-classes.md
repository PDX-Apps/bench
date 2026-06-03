# SERVICE-001-service-classes

## Pattern

Service classes (or modules) encapsulate API operations for a domain. They expose typed methods that wrap HTTP calls and return mapped Model instances (never raw response payloads).

In React, services are typically **static-method classes** or **plain object modules** — DI containers are rare. Discover the convention from sibling services before writing a new one.

## Structure — Static-method style (default, simplest)

```typescript
import { http } from 'src/services/http';   // project's HTTP client (axios, ky, fetch wrapper)
import { Bill } from '../models';
import type {
  BillListResponse,
  BillResponse,
  CreateBillPayload,
  UpdateBillPayload,
} from '../types/bill.types';

/**
 * Service for managing bill API operations
 */
export class BillService {
  // ==================== CRUD ====================

  static async list(): Promise<Bill[]> {
    const response = await http.get<BillListResponse>('/api/v1/bills');
    return response.data.map((b) => Bill.fromApi(b));
  }

  static async get(billId: string): Promise<Bill> {
    const response = await http.get<BillResponse>(`/api/v1/bills/${billId}`);
    return Bill.fromApi(response.data);
  }

  static async create(payload: CreateBillPayload): Promise<Bill> {
    const response = await http.post<BillResponse>('/api/v1/bills', payload);
    return Bill.fromApi(response.data);
  }

  static async update(billId: string, payload: UpdateBillPayload): Promise<Bill> {
    const response = await http.put<BillResponse>(`/api/v1/bills/${billId}`, payload);
    return Bill.fromApi(response.data);
  }

  static async delete(billId: string): Promise<void> {
    await http.delete(`/api/v1/bills/${billId}`);
  }
}
```

## Structure — Plain object module (alternative)

If the project prefers plain objects:

```typescript
export const BillService = {
  async list(): Promise<Bill[]> { ... },
  async get(id: string): Promise<Bill> { ... },
  // ...
};
```

Both shapes work. Match what sibling services do.

## Method Organization

Group methods with `// ====` separator comments by resource/action area:

```typescript
// ==================== CRUD ====================
static async list(...): Promise<Bill[]> { ... }
static async get(...): Promise<Bill> { ... }

// ==================== Actions ====================
static async markPaid(...): Promise<Bill> { ... }
static async skip(...): Promise<Bill> { ... }
```

## Return Mapped Models

Services NEVER return raw API data. Always map through the Model's static factory:

```typescript
// ✅ Right
return Bill.fromApi(response.data);
return response.data.map((b) => Bill.fromApi(b));

// ❌ Wrong
return response.data;
```

This ensures consumers always get class instances with computed getters and domain methods.

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{Name}Service.ts` | `BillService.ts` |
| Class | `{Name}Service` | `BillService` |
| Location | `src/modules/{Module}/services/` | `Bill/services/BillService.ts` |

## Type Imports

Always import payload + response types from a sibling `../types/{namespace}.types.ts`:

```typescript
import type {
  BillListResponse,
  BillResponse,
  CreateBillPayload,
  UpdateBillPayload,
} from '../types/bill.types';
```

See TYPE-001 for type file conventions.

## Key Points

- Static methods (or plain object module) — pick what matches the project
- Return `Model` instances (always use `Model.fromApi()`)
- Group methods with `// ====` separator comments
- Type all payloads + responses (TYPE-001)
- See SERVICE-002 for accessing services from components
- See MODEL-001 for the Model + factory pattern
