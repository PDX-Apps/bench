---
description: Generate Laravel Eloquent models, query builders, model traits, and enums for status/type fields. Use whenever the user mentions a model, entity, database record, Eloquent class, query scope, or domain object with state/behavior in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/model** skill. Translate the user's request into an enriched delegation to the `model` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Model name** (Bill, BillMember, Household)
- **Sub-artifacts requested**: query-builder? trait? enum(s)? (the model class itself is mandatory)
- **Domain methods hinted at** (state transitions like `accept()`, `markPaid()`)

## Step 2: Inspect

```bash
# Module + sibling models
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Models/ 2>/dev/null
ls Modules/{Module}/app/Builders/ 2>/dev/null
ls Modules/{Module}/app/Enums/ 2>/dev/null
ls Modules/{Module}/database/migrations/ 2>/dev/null  # is the table already migrated?
```

## Step 3: Resolve Ambiguity

- Module missing → suggest `/new-module {Module}`
- No migration for the table yet → flag: "I'll generate the model. Run `/migration` after to create the table, OR confirm the table already exists."
- Public ID column needed (API-facing model)? Default yes for resources exposed via API; ask if unclear.
- For complex state machines, confirm enum vs string column choice.

## Step 4: Build Context Blob

```
Context for model agent:
- Module: {Module}
- Model name: {Name}
- Path: Modules/{Module}/app/Models/{Name}.php
- Public ID: {yes|no} (API-exposed?)
- Existing siblings: [Bill.php, BillMember.php]
- Existing builders/enums: [BillBuilder, BillStatus]
- Sub-artifacts to generate: [Builders/{Name}Builder, Enums/{Name}Status]
- Domain methods hinted: [accept(), markPaid()]
- Migration status: {exists|to-be-created}
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:model"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Models/Bill.php` with `casts()`, `HasPublicId` trait, and domain methods `markPaid()`/`skip()`. Factory at `database/factories/BillFactory.php`. Created `Builders/BillBuilder.php` and `Enums/BillStatus.php`. Use `/migration` next to add the `bills` table."

## When to Ask vs Assume

- Public ID needed → assume YES for any model under a module's `Models/` (they're API-facing). Only ask for internal-only models.
- Sub-artifacts → assume the user wants what they explicitly named; don't auto-create extras
- Tests → don't generate here; suggest `/feature-test` or `/unit-test` after
