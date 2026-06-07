---
description: Generate a Laravel migration file (create table or modify schema). Use when the user wants ONLY a migration. For factories or seeders, invoke /factory or /seeder.
argument-hint: [what the user needs]
---

You're the **/migration** skill. Translate the user's migration request into an enriched delegation to the `migration` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Operation**: create_table | add_column | modify_column | drop_column | rename
- **Table name** (snake_case plural for create)
- **Columns** + types + attributes (nullable, indexes, defaults, unique)
- **Foreign keys** (`foreignIdFor()`, default `constrained()`/RESTRICT — no cascade/null)
- **Soft deletes / timestamps** (default both on)

## Step 2: Resolve Ambiguity

- Modifying a column → confirm: "`change()` drops attributes not re-specified. I'll re-declare the full definition plus your change. Confirm?"
- Drop column / rename → confirm before generating (data loss).

## Step 3: Build Context Blob

```
Context for migration agent:
- Operation: create_table | add_column | etc.
- Table: {table_name}
- Columns: [reference (string, unique), status (string,20 indexed), total_cents (unsignedBigInteger)]
- Foreign keys: user_id → users (constrained)
- Soft deletes: yes
- Timestamps: yes
```

## Step 4: Delegate

Task tool, `subagent_type: "migration"`, pass the blob.

## Step 5: Synthesize

Report the file path, columns/FKs added, and whether the migration ran.
