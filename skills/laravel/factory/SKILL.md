---
description: Generate a Laravel model factory (database/factories/{Model}Factory.php). Use when the user wants ONLY a factory.
argument-hint: [what the user needs]
---

You're the **/factory** skill. Translate the user's factory request into an enriched delegation to the `factory` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Model** the factory is for (must exist)
- **State methods** (`paid()`, `forHousehold($h)`, `overdue()`)
- **Default attributes** — Faker for realistic data; `PublicId::generate()` for public IDs

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/database/factories/ 2>/dev/null
ls Modules/{Module}/app/Models/{Model}.php 2>/dev/null
ls Modules/{Module}/database/migrations/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Model missing → flag: "Generate `/model` first?"
- Migration missing → flag: factory needs to know required columns
- State methods unclear → ask "Common variations? (`paid()`, `overdue()`, `forHousehold($h)`?)"

## Step 4: Build Context Blob

```
Context for factory agent:
- Module: {Module}
- Model: {Model} at Modules/{Module}/app/Models/{Model}.php
- Factory class: {Model}Factory
- Path: Modules/{Module}/database/factories/{Model}Factory.php
- PHPDoc: @extends Factory<{Model}>  (REQUIRED for static analysis)
- definition() defaults:
    public_id: PublicId::generate()
    name: fake()->words(3, true)
    amount: fake()->numberBetween(100, 100000)
    status: BillStatus::Unpaid
- State methods: [paid(), forHousehold(Household $h)]
- afterCreating() hooks: [if any]
- Existing siblings: [BillFactory.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:factory"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/database/factories/BillFactory.php`. PHPDoc `@extends Factory<Bill>`. State methods: paid, overdue, forHousehold. Usable: `Bill::factory()->paid()->create()`."

## When to Ask vs Assume

- `@extends Factory<Model>` PHPDoc → always
- `PublicId::generate()` → always for public IDs
- State naming: `withField()` for fields, `forRelation()` for relations
