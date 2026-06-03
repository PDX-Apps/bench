# TYPE-001-types-and-payloads

## Pattern

Each module has a `types/{namespace}.types.ts` file declaring the API contract types: request payloads, response shapes, and API-specific aliases. Models (MODEL-001) own runtime classes; types own static API shape.

## Structure

```typescript
// src/modules/Bill/types/bill.types.ts

import type { IBill } from '../models/Bill';
import type { IBillMember } from '../models/BillMember';

// ==================== Request Payloads ====================

export interface CreateBillPayload {
  name: string;
  amount: number;
  dueDate: string;
  memberIds?: string[];
}

export interface UpdateBillPayload {
  name?: string;
  amount?: number;
  dueDate?: string;
}

// ==================== Response Shapes ====================

export interface BillResponse {
  data: IBill;
}

export interface BillListResponse {
  data: IBill[];
  meta?: {
    total: number;
    page: number;
    perPage: number;
  };
}

// ==================== Aliases ====================

export type BillStatus = IBill['status'];  // 'unpaid' | 'paid' | 'partial' | 'skipped'
```

## Conventions

- `Create{Name}Payload`, `Update{Name}Payload` — what the client sends
- `{Name}Response` — single-item GET/POST/PUT response
- `{Name}ListResponse` — collection GET response (often with pagination meta)
- `{Name}Filters` — query string params for list endpoints

## Location

| Item | Path |
|------|------|
| Types file | `src/modules/{Module}/types/{namespace}.types.ts` |
| Namespace | usually module name lowercase (`bill`, `household`) |

## Imports

Types import the interface from the model (NOT the class), so types stay decoupled from class behavior:

```typescript
import type { IBill } from '../models/Bill';
```

## Discriminated Unions for Status

If response shape differs by status, use discriminated unions:

```typescript
export type BillProcessingResponse =
  | { status: 'queued'; jobId: string }
  | { status: 'completed'; result: IBill }
  | { status: 'failed'; error: string };
```

Consumers narrow via the discriminant:

```typescript
if (response.status === 'completed') {
  // response.result is IBill
}
```

## Anti-Patterns

```typescript
// ❌ Types depending on classes — couples them
import { Bill } from '../models/Bill';
export interface BillResponse { data: Bill; }  // wrong

// ✅ Types use the interface
import type { IBill } from '../models/Bill';
export interface BillResponse { data: IBill; }
```

```typescript
// ❌ Inlining payloads in service signatures
async function createBill(name: string, amount: number, dueDate: string) { ... }

// ✅ Use a named payload type
async function createBill(payload: CreateBillPayload) { ... }
```

## Key Points

- One types file per module's namespace: `{namespace}.types.ts`
- `Create*Payload`, `Update*Payload`, `*Response`, `*ListResponse` conventions
- Import interfaces (`I{Name}`) not classes
- Discriminated unions for status-shaped responses
- Stay decoupled from class behavior — types are static shape only
