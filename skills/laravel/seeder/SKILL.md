---
description: Generate a Laravel database seeder. Use when the user wants test data populated for a model in dev/staging/test environments.
argument-hint: [what the user needs]
---

You're the **/seeder** skill. Translate the user's seeder request into an enriched delegation to the `seeder` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Seeder class** — `{Model}Seeder`
- **What to seed** (count + variations)
- **Dependencies** on other seeders

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/database/seeders/ 2>/dev/null
ls Modules/{Module}/database/factories/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Factory missing → flag: "Seeder uses factory — `BillFactory` doesn't exist. Generate `/factory` first?"
- Idempotency needed → for prod-touching seeders yes; for dev test data usually not
- Registration in DatabaseSeeder → assume yes

## Step 4: Build Context Blob

```
Context for seeder agent:
- Module: {Module}
- Class: {Model}Seeder
- Path: Modules/{Module}/database/seeders/{Model}Seeder.php
- Uses factory: {Model}Factory
- What to seed:
    50 random bills via factory()
    10 paid bills via factory()->paid()
    5 overdue bills via factory()->overdue()
- Idempotency: yes if prod-bound, no for dev test data
- Register in: Modules/{Module}/database/seeders/DatabaseSeeder.php
- Existing siblings: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:seeder"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/database/seeders/BillSeeder.php`. Seeds 50 random + 10 paid + 5 overdue via factory states. Registered in `DatabaseSeeder`."

## When to Ask vs Assume

- Use factory → always
- Registration in DatabaseSeeder → assume yes
- Idempotency → only for prod-touching seeders
