# VALIDATOR-001-zod-schemas

## Pattern

Zod validation schemas as **factory functions** that return fresh schema instances. Factories enable per-consumer customization and prevent shared-state issues. The same pattern works for both Vue and React.

## Structure

```typescript
import { z } from 'zod';

/**
 * Email schema — RFC 5322 + reasonable length
 */
export const emailSchema = () =>
  z.string().email().max(255);

/**
 * Password schema — project policy (min 8, max 100)
 */
export const passwordSchema = () =>
  z.string().min(8).max(100);

/**
 * Bill amount — positive, finite, max 2 decimals
 */
export const billAmountSchema = () =>
  z.number().positive().finite().multipleOf(0.01);

/**
 * Bill name — non-empty, max 100 chars
 */
export const billNameSchema = () =>
  z.string().min(1).max(100).trim();

/**
 * Composite — full bill form schema
 */
export const billFormSchema = () =>
  z.object({
    name: billNameSchema(),
    amount: billAmountSchema(),
    dueDate: z.string().datetime(),
    memberIds: z.array(z.string()).optional(),
  });
```

## Why Factory Functions (not const exports)

```typescript
// ❌ Const — single shared instance
export const emailSchema = z.string().email();
// Every consumer references the same object. Trying to add custom error
// messages or extend mutates it for everyone. Surprising bugs.

// ✅ Factory — fresh instance per call
export const emailSchema = () => z.string().email();
// Each consumer gets their own; safe to `.refine()`, customize messages, etc.
```

## Usage in React Hook Form (the common case)

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { billFormSchema } from '../validators/billValidators';

const form = useForm({
  resolver: zodResolver(billFormSchema()),
});
```

## Usage in Plain Validation

```typescript
import { emailSchema } from '../validators/userValidators';

const result = emailSchema().safeParse(input);
if (!result.success) {
  console.log(result.error.issues);  // formatted errors
}
```

## Custom Error Messages

Default Zod messages are technical. Provide user-friendly versions where it matters:

```typescript
export const billAmountSchema = () =>
  z.number({
    invalid_type_error: 'Amount must be a number',
  })
  .positive('Amount must be greater than zero')
  .finite('Amount is required');
```

Or globalize via i18n at the resolver level (project-specific).

## Composition + Refinement

Schemas compose freely:

```typescript
export const createBillSchema = () =>
  z.object({
    name: billNameSchema(),
    amount: billAmountSchema(),
  }).refine(
    (data) => data.amount < 1000000,
    { message: 'Amount exceeds maximum', path: ['amount'] },
  );
```

## Naming + Location

| Item | Convention | Example |
|------|-----------|---------|
| File | `{namespace}Validators.ts` | `billValidators.ts`, `authValidators.ts` |
| Function | `{thing}Schema` | `emailSchema`, `billAmountSchema` |
| Location | `src/modules/{Module}/validators/` | `Bill/validators/billValidators.ts` |

## Key Points

- Schemas as factory functions (NOT const exports)
- Compose primitives into composite schemas at consumption
- Use with react-hook-form's `zodResolver` for forms
- Use `safeParse(...)` for non-form validation paths
- Provide friendly error messages where the default is technical
- See COMPONENT-002 for form integration
