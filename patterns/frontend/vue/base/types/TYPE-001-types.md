# Types & payloads

TypeScript types for domain entities and API payloads. Prefer **deriving types from Zod schemas** where a runtime boundary exists; use plain interfaces for everything else.

## Domain entities — plain interfaces

```ts
// types/user.ts
export interface User {
  id: string
  firstName: string
  lastName: string
  email: string
  createdAt: string // ISO; parse to Date at the edge if needed
}
```

## Payloads — derive from the Zod schema (single source of truth)

When a value crosses the network boundary, the [Zod schema](../validation/VALIDATOR-001-zod.md) is the source of truth and the type comes from it:

```ts
// validation/user.ts
import { z } from 'zod'

export const createUserSchema = z.object({
  firstName: z.string().min(1),
  email: z.string().email(),
})

export type CreateUserPayload = z.infer<typeof createUserSchema>
```

```ts
// types/user.ts
import type { CreateUserPayload } from '@/validation/user'
export type UpdateUserPayload = Partial<CreateUserPayload>
```

## Conventions

- **`interface` for object shapes**, `type` for unions/utilities/derived (`z.infer`, `Partial<>`, `Pick<>`).
- **Derive payload types from Zod** (`z.infer`) — never hand-write a type that duplicates a validation schema.
- **Name by role**: entity = noun (`User`); inputs = `Create*Payload` / `Update*Payload`; API envelopes = `*Response` only if the server wraps data.
- **No `any`.** Use `unknown` + narrowing at boundaries.
- **Co-locate** entity types in `types/`, payload schemas+types alongside their Zod schema in `validation/`.

## Don't

- Don't keep a hand-written type and a Zod schema in sync manually — derive one from the other.
- Don't model server-wrapper shapes (`{ data, meta }`) into every entity — unwrap in the HTTP client.

## See also

- [VALIDATOR-001](../validation/VALIDATOR-001-zod.md) · [QUERY-001](../data/QUERY-001-tanstack-query.md)
