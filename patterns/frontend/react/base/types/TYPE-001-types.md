# Types & payloads

TypeScript types for domain entities and API payloads. **Derive types from Zod schemas** where a runtime boundary exists; plain interfaces otherwise.

## Domain entities — interfaces

```ts
// types/user.ts
export interface User {
  id: string
  firstName: string
  lastName: string
  email: string
  createdAt: string // ISO
}
```

## Payloads — derive from the Zod schema (single source of truth)

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
export type UpdateUserPayload = Partial<CreateUserPayload>
```

## Conventions

- **`interface` for object shapes**, `type` for unions/utilities/derived (`z.infer`, `Partial`, `Pick`).
- **Derive payload types from Zod** (`z.infer`) — never hand-write a type that duplicates a schema.
- **Name by role**: entity = noun (`User`); inputs = `Create*Payload` / `Update*Payload`; envelopes = `*Response` only if the server wraps data.
- **No `any`** — `unknown` + narrowing at boundaries.
- **Prop types** live with their component (`{Name}Props`); shared domain types in `types/`.

## Don't

- Don't keep a hand-written type and a Zod schema in sync manually — derive one from the other.
- Don't bake server-wrapper shapes into every entity — unwrap in the HTTP client.
