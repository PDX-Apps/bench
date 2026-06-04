---
description: Generate Zod validation schemas (factory functions) for a Vue 3 frontend. Use whenever the user mentions form validation, Zod schemas, input validation, validators, or runtime data validation in the frontend project.
argument-hint: [what the user needs]
---

You're the **/vue-validator** skill. Translate the user's validation request into an enriched delegation to the `vue-validator` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Auth, Bill, etc.)
- **Validators file** — `{namespace}Validators.ts`
- **Schema function names** — `{thing}Schema`
- **What's being validated** — primitive or composite
- **Where consumed** — which form components

## Step 2: Inspect

```bash
ls src/modules/{Module}/validators/ 2>/dev/null || echo "MODULE_MISSING_OR_NO_VALIDATORS"
ls src/modules/{Module}/components/Forms/ 2>/dev/null
grep -rh "from 'zod" src/modules/{Module}/validators/ 2>/dev/null | head -3
```

## Step 3: Resolve Ambiguity

- Constraints unclear → infer from backend's VAL-* doc if exists; else ask one question
- Composite vs primitives → default to primitives that compose at consumption

## Step 4: Build Context Blob

```
Context for vue-validator agent:
- Module: {Module}
- File: src/modules/{Module}/validators/{namespace}Validators.ts
- New file or extend existing: extend
- Zod import style: discover from existing (e.g., `import * as z from 'zod/v4'` vs `import { z } from 'zod'`)
- Schemas to add:
    emailSchema: () => ZodSchema = () => z.string().email()
    passwordSchema: () => ZodSchema = () => z.string().min(8).max(100)
- Factory pattern: (no const exports — always functions returning fresh instances)
- Used by forms: [LoginForm.vue, BillForm.vue]
- Existing schemas: [emailSchema, passwordSchema]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:vue-validator"`, pass the blob.

## Step 6: Synthesize

> "Added `billAmountSchema()` and `billNameSchema()` to `src/modules/Bill/validators/billValidators.ts`. Factory functions returning fresh Zod instances."

## When to Ask vs Assume

- Factory function pattern (NOT const) → always
- Zod import style → match existing project convention
- Return type annotations → always
