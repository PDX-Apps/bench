---
description: Add OpenAPI/Swagger annotations to Laravel Models, FormRequests, Resources, and Controllers via #[OA\...] PHP attributes. Project uses darkaonline/l5-swagger.
argument-hint: [what the user needs]
---

You're the **/swagger** skill. Translate the user's Swagger request into an enriched delegation to the `swagger` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (or all)
- **Target classes**: Models | FormRequests | Resources | Controllers (one or more)
- **Operations** to document (Get/Post/Put/Delete on which controllers)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls config/l5-swagger.php 2>/dev/null
grep -rln "#\[OA\\\\" Modules/{Module}/ --include="*.php" 2>/dev/null  # existing usage
```

## Step 3: Resolve Ambiguity

- Targets unclear → ask: "Which classes need annotations? Models, FormRequests, Resources, Controllers, or all?"
- Schemas defined elsewhere → never duplicate; reference via `ref:`
- Spec regeneration → assume `php artisan l5-swagger:generate` after

## Step 4: Build Context Blob

```
Context for swagger agent:
- Module: {Module}
- Targets:
    Models: [Bill] → #[OA\Schema(schema: 'Bill')]
    Resources: [BillResource] → #[OA\Schema(...)] for response shape
    FormRequests: [CreateBillRequest] → #[OA\Schema(...)] for request body
    Controllers: [BillController] → #[OA\Get], #[OA\Post] etc. for operations
- Existing schemas (don't duplicate): [User, Household]
- Spec regen needed: yes (run php artisan l5-swagger:generate after)
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:swagger"`, pass the blob.

## Step 6: Synthesize

> "Added OpenAPI annotations: `#[OA\Schema]` on Bill, BillResource, CreateBillRequest. `#[OA\Post]`, `#[OA\Get]` on BillController CRUD methods. Ran `l5-swagger:generate` — spec validates, accessible at `/api/documentation`."

## When to Ask vs Assume

- PHP attributes (#[OA\\...]) NOT PHPDoc style → always
- Schemas via `ref:` (never inline duplicates) → always
- Generate spec after → always
