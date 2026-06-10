# Validation — Zod schemas

[Zod](https://zod.dev) schemas are the single source of truth for shape + runtime validation at boundaries (forms via react-hook-form, API payloads, env). The TypeScript type is **derived** from the schema.

## Shape

```ts
// validation/user.ts
import { z } from 'zod'

export const createUserSchema = z.object({
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  email: z.string().email('Enter a valid email'),
  role: z.enum(['admin', 'member']).default('member'),
})

export type UserFormValues = z.infer<typeof createUserSchema>
export const updateUserSchema = createUserSchema.partial()
```

## Use it

- **Forms** — pass to react-hook-form via `zodResolver(createUserSchema)`. Messages surface as `errors.field.message`.
- **API responses** — `schema.parse(data)` in the query fetcher to fail loudly on shape drift.
- **Compose** — `.partial()`, `.pick()`, `.extend()`, `.merge()` instead of hand-writing variants.

## Conventions

- **One schema per boundary**, `{action}{Entity}Schema`; export the `z.infer` type beside it.
- **Messages live in the schema** so forms don't restate rules. (i18n: pass a message map / keys.)
- **`safeParse` for manual checks**, `zodResolver` for forms, `parse` for trusted-but-verify.
- **Coerce at the edge** (`z.coerce.number()` for query params); keep domain types clean.

## Don't

- Don't hand-write a TS type that mirrors a schema — use `z.infer`.
- Don't validate the same thing twice — compose from one schema.
- Don't skip validating API responses if the backend shape can drift.
