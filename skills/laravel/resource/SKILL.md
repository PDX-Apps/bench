---
description: Generate a Laravel API Resource (JsonResource transformer). Use when the user wants ONLY a Resource (not the full HTTP stack). For full HTTP layer, use /api instead.
argument-hint: [what the user needs]
---

You're the **/resource** skill. Translate the user's API Resource request into an enriched delegation to the `resource` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Resource class name** — `{Model}Resource`
- **Model** being transformed
- **Fields to expose** (subset of model attributes + relations)
- **Nested relations** (using `whenLoaded()` to avoid N+1)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Http/Resources/ 2>/dev/null
ls Modules/{Module}/app/Models/ 2>/dev/null  # confirm model exists
```

Sample sibling:
```bash
cat Modules/{Module}/app/Http/Resources/$(ls Modules/{Module}/app/Http/Resources/ 2>/dev/null | head -1) 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Fields not specified → discover from the model's attributes; ask "Expose all model attributes or a subset?"
- Nested relations → wrap each with `whenLoaded()` (assume yes, never load eagerly in resource)
- Public ID exposure as `id` → assume yes (project convention: never expose internal `id`)

## Step 4: Build Context Blob

```
Context for resource agent:
- Module: {Module}
- Class: {Model}Resource
- Path: Modules/{Module}/app/Http/Resources/{Model}Resource.php
- Model: {Model} at Modules/{Module}/app/Models/{Model}.php
- Fields to expose (id = public_id; never internal id):
    id, name, amount, currency, status, due_date, created_at
- Nested relations (use whenLoaded):
    members → BillMemberResource::collection
    creator → UserResource
- Swagger #[OA\Schema] needed: yes (project uses l5-swagger)
- Existing siblings: [BillResource.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:resource"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Http/Resources/BillResource.php`. Exposes 7 fields + nested `members` (whenLoaded). `id` returns `public_id`. Includes `#[OA\Schema(schema: 'Bill')]` for Swagger."

## When to Ask vs Assume

- `id` from `public_id` → always (NEVER internal id)
- `whenLoaded()` for relations → always
- `#[OA\Schema]` for Swagger → assume yes (project uses it)
