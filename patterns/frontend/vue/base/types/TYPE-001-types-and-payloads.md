# TYPE-001-types-and-payloads

## Pattern

`*.types.ts` files contain request payload and response interface definitions for a domain. They re-export model interfaces for backwards compat and consumer convenience.

## Structure

```typescript
import type { IBill, IBillMember, BillFrequency, BillStatus } from '../models';

// Re-export models and types for convenience
export type { IBill, IBillMember, BillFrequency, BillStatus };
export { Bill, BillMember } from '../models';

/**
 * Member split data passed when creating/updating household bills
 */
export interface MemberSplit {
  user_id: string;
  split_amount: number;
}

/**
 * Request payload for creating a personal bill
 */
export interface CreatePersonalBillPayload {
  name: string;
  amount: number;
  currency: string;
  frequency: BillFrequency;
  start_date: string;
  is_auto_pay?: boolean;
  notes?: string;
}

/**
 * Request payload for updating a bill (all fields optional)
 */
export interface UpdateBillPayload {
  name?: string;
  amount?: number;
  // ... etc
}

/**
 * Response wrapper for a list of bills
 */
export interface BillListResponse {
  data: IBill[];
}

/**
 * Response wrapper for a single bill
 */
export interface BillResponse {
  data: IBill;
}
```

## Naming Conventions

| Type | Suffix | Example |
|------|--------|---------|
| Request payload (create) | `Create{Name}Payload` | `CreatePersonalBillPayload` |
| Request payload (update) | `Update{Name}Payload` | `UpdateBillPayload` |
| Request payload (specific action) | `{Action}{Name}Payload` | `RefundPaymentPayload` |
| Response (list) | `{Name}ListResponse` | `BillListResponse` |
| Response (single) | `{Name}Response` | `BillResponse` |
| Sub-payload | descriptive | `MemberSplit`, `Address` |

## Layout Pattern

Standard structure for a `*.types.ts` file:

1. **Imports** — bring in interfaces from models
2. **Re-exports** — re-export model interfaces and classes for convenience
3. **Sub-payload types** — small composable shapes (`MemberSplit`)
4. **Create payloads** — request bodies for `POST` operations
5. **Update payloads** — request bodies for `PUT/PATCH` (mostly optional fields)
6. **Specialized payloads** — action-specific (`UpdateMemberSplitPayload`)
7. **Response wrappers** — match the API's `{ data: ... }` envelope shape

## File Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{namespace}.types.ts` (lowercase) | `bill.types.ts`, `household.types.ts` |
| Location | `src/modules/{Module}/types/` | `Bill/types/bill.types.ts` |
| One file per resource | not per type | `bill.types.ts` covers Bill + BillMember + payloads |

## Optional vs Required Fields

- **Create payloads**: required fields without `?`, optional with `?`
- **Update payloads**: nearly everything `?` (partial updates)
- **Response data**: required (the API guarantees these)

```typescript
// Create — name and amount required, notes optional
interface CreateBillPayload {
  name: string;        // required
  amount: number;      // required
  notes?: string;      // optional
}

// Update — all optional
interface UpdateBillPayload {
  name?: string;
  amount?: number;
  notes?: string;
}
```

## API Envelope

The backend wraps all responses in `{ data: ... }`. Reflect this in response types:

```typescript
interface BillResponse {
  data: IBill;        // single — `data` is the object
}

interface BillListResponse {
  data: IBill[];      // list — `data` is an array
}
```

In services, access via `response.data`:

```typescript
const response = await this.api.get<BillResponse>(`/api/v1/bills/${id}`);
return Bill.fromApi(response.data);
```

## When to Add a New `*.types.ts` File

- A new domain (separate resource): new file (`payment.types.ts`)
- A new operation on existing resource: add to existing file
- Cross-module types: live in `src/types/` or the consuming module's `types/`

## Key Points

- One `{namespace}.types.ts` per domain
- Re-export model interfaces for convenience
- `Create*Payload`, `Update*Payload`, `*Response`, `*ListResponse` naming
- Update payloads have mostly `?` (optional) fields
- Response types reflect the `{ data: ... }` envelope
- See MODEL-001 for the model interface (`I{Name}`) — defined in the model file, re-exported here
- See SERVICE-001 for how services consume these types
