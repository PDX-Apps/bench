# SERVICE-001-service-classes

## Pattern

Service classes encapsulate API operations for a domain. They expose typed methods that wrap HTTP calls and return mapped Model instances (never raw response payloads).

The exact structure (static methods vs class instances, DI vs plain imports) depends on the project. Discover the convention from sibling services before writing a new one.

## Structure — Static-method style (default, simplest)

```typescript
import { http } from 'src/services/http';   // project's HTTP client (axios wrapper, fetch helper, etc.)
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
    return response.data.map(b => Bill.fromApi(b));
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

## Structure — DI / container style

If the project uses a DI container or framework wrapper, follow that convention. Typical shape:

```typescript
export class BillService extends Service implements  {
  private api!: ApiService;
  register({ api }: ServiceContainer): void { this.api = api; }

  async list(): Promise<Bill[]> { ... }
}
```

Match what sibling services do.

## Method Organization

Group methods with `// ====` separator comments by resource/action area:

```typescript
// ==================== CRUD ====================
async list(...): Promise<Bill[]> { ... }
async get(...): Promise<Bill> { ... }
async update(...): Promise<Bill> { ... }

// ==================== Actions ====================
async markPaid(...): Promise<Bill> { ... }
async skip(...): Promise<Bill> { ... }
```

## Return Mapped Models

Services NEVER return raw API data. Always map through the Model's static factory:

```typescript
// ✅ Right
return Bill.fromApi(response.data);
return response.data.map(b => Bill.fromApi(b));

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

- Discover project convention (static methods vs DI class) from sibling services
- Return `Model` instances (always use `Model.fromApi()`)
- Group methods with `// ====` separator comments by area
- Type all payloads + responses (TYPE-001)
- See SERVICE-002 for accessing services from components
- See MODEL-001 for the Model + factory pattern
