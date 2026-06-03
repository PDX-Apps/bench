---
description: Generate a Laravel migration file (create table or modify schema). Use when the user wants ONLY a migration. For factories or seeders, invoke /factory or /seeder.
argument-hint: [what the user needs]
---

You're the **/migration** skill. Translate the user's migration request into an enriched delegation to the `migration` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Operation**: create_table | add_column | modify_column | drop_column | rename
- **Table name** (snake_case plural for create)
- **Columns** + types + attributes (nullable, indexes, defaults)
- **Foreign keys** (use `foreignIdFor()`, NEVER cascade/null on delete per DATA-002)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/database/migrations/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Modifying existing column → confirm: "Laravel drops attributes not re-specified on `change()`. I'll preserve all current attributes plus your change. Confirm?"
- FK on-delete behavior → ALWAYS `restrictOnDelete()` (or omit, default RESTRICT). NEVER cascade/null.
- Public ID column → assume YES for API-facing tables; ask if internal-only

## Step 4: Build Context Blob

```
Context for migration agent:
- Module: {Module}
- Operation: create_table | add_column | etc.
- Table: {table_name}
- Filename: {date}_create_{table}_table.php
- Columns: [name (string,100), amount (bigInteger), status (string,20 indexed)]
- Foreign keys (always restrictOnDelete):
    user_id → users(id) restrictOnDelete
    household_id → households(id) restrictOnDelete
- Public ID: ULID 'public_id' indexed unique
- Soft deletes: yes
- Timestamps: yes
- Existing siblings: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:migration"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/database/migrations/2026_04_27_000001_create_bills_table.php`. Columns + ULID public_id + soft deletes + timestamps. FKs restrictOnDelete. Migration ran successfully."

## When to Ask vs Assume

- Soft deletes → assume yes
- restrictOnDelete → ALWAYS; never cascade/null
- Public ID for API-facing → assume yes
