# Validation — Zod schemas

[Zod](https://zod.dev) schemas are the single source of truth for shape + runtime validation at boundaries (forms, API payloads, env, URL params). The TypeScript type is **derived** from the schema, never duplicated.

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

// the form/payload type comes from the schema
export type UserFormValues = z.infer<typeof createUserSchema>

export const updateUserSchema = createUserSchema.partial()
```

## Use it

- **Forms** — `schema.safeParse(form)` on submit; map `result.error.issues` to per-field messages ([COMPONENT-002](../components/COMPONENT-002-forms.md)).
- **API responses** — `schema.parse(data)` in the HTTP client / query fetcher to fail loudly on shape drift.
- **Reuse + compose** — `.partial()`, `.pick()`, `.extend()`, `.merge()` instead of writing variants by hand.

```ts
const result = createUserSchema.safeParse(input)
if (!result.success) {
  /* result.error.issues: { path, message }[] */
} else {
  /* result.data is typed UserFormValues */
}
```

## Conventions

- **One schema per boundary**, named `{action}{Entity}Schema` (`createUserSchema`); export the inferred type next to it.
- **`safeParse` for user input** (you handle errors), **`parse` for trusted-but-verify** (throws).
- **Messages live in the schema** so forms don't restate rules. (For i18n, pass keys/messages from a factory — see [I18N-001](../i18n/I18N-001-vue-i18n.md).)
- **Coerce at the edge** (`z.coerce.number()` for query params), keep domain types clean.

## Don't

- Don't hand-write a TS type that mirrors a schema — use `z.infer`.
- Don't validate the same thing in two places — compose from one schema.
- Don't skip validating API responses if the backend shape can drift.

## See also

- [TYPE-001](../types/TYPE-001-types.md) · [COMPONENT-002](../components/COMPONENT-002-forms.md)
