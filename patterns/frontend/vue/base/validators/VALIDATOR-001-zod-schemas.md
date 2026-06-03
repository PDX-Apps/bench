# VALIDATOR-001-zod-schemas

## Pattern

Validation schemas are Zod schemas exported as **factory functions** (not values). They're consumed by `BaseInput` for inline form validation and can be used directly anywhere runtime validation is needed.

## Structure

```typescript
import * as z from 'zod/v4';

/**
 * Email validation
 */
export const emailSchema = (): z.ZodEmail => z.email();

/**
 * Password validation: 8-100 chars
 */
export const passwordSchema = (): z.ZodString => z.string().min(8).max(100);

/**
 * Name validation: 2-30 chars
 */
export const nameSchema = (): z.ZodString => z.string().min(2).max(30);

/**
 * Object schema for resetting password from URL query params
 */
export const resetPasswordTokenSchema = () =>
  z.object({
    form: z.literal('password-reset'),
    token: z
      .string()
      .length(64)
      .regex(/^[a-zA-Z0-9]+$/),
  });
```

## Why Factories?

Each call returns a fresh schema instance. This avoids accidental shared state and keeps schema construction lazy.

```typescript
// ✅ Factory — fresh instance per call
export const emailSchema = (): z.ZodEmail => z.email();
const s1 = emailSchema();
const s2 = emailSchema();  // different instance

// ❌ Not the convention — exported value
export const emailSchema = z.email();
```

## Usage with BaseInput

`BaseInput` accepts a `schema` prop and runs validation on input/blur:

```vue
<BaseInput
  v-model="email"
  :schema="emailSchema()"
  type="email"
  :label="i18n.t('auth.form.email')"
  required
/>
```

The `()` invocation is important — pass the result, not the function reference.

## Usage Standalone

For runtime validation outside of forms (URL parsing, API response checks):

```typescript
const schema = resetPasswordTokenSchema();
const result = schema.safeParse(route.query);

if (result.success) {
  const { token } = result.data;  // typed!
} else {
  // result.error contains validation issues
}
```

## Composing Schemas

Build complex schemas from primitives:

```typescript
export const loginSchema = () =>
  z.object({
    email: emailSchema(),       // call the factory!
    password: passwordSchema(),
    remember: z.boolean().optional(),
  });
```

## Custom Refinements

For business rules that go beyond type checks:

```typescript
export const billAmountSchema = () =>
  z
    .number()
    .positive('Amount must be greater than zero')
    .refine((v) => Number.isFinite(v) && v < 1_000_000_000, {
      message: 'Amount exceeds maximum',
    });
```

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{namespace}Validators.ts` | `authValidators.ts`, `billValidators.ts` |
| Location | `src/modules/{Module}/validators/` | `Auth/validators/authValidators.ts` |
| Function name | `{thing}Schema` | `emailSchema`, `passwordSchema`, `loginSchema` |
| Return type | `(): z.ZodType<...>` annotation when not inferable | `(): z.ZodEmail`, `(): z.ZodString` |

## Error Messages

Default Zod messages are usable but generic. Override per-field for user-friendly text:

```typescript
export const passwordSchema = () =>
  z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(100, 'Password is too long');
```

For i18n, do the lookup at the call site (the schema returns a generic message; the consumer translates):

```vue
<BaseInput
  v-model="password"
  :schema="passwordSchema()"
  :error-message="i18n.t('auth.errors.invalidPassword')"
/>
```

## Key Points

- Always export schemas as **factory functions** — call `()` to use
- Use `zod/v4` import (project uses Zod 3 but with v4 API alias)
- Co-locate schemas per domain in `{namespace}Validators.ts`
- Return type annotations help IDE inference
- Compose primitives into object schemas for full forms
- Use with `BaseInput :schema="emailSchema()"` for form validation
- Use `safeParse()` for non-form runtime validation
