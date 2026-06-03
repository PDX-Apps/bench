---
description: Generate a custom Laravel Eloquent query builder class (extends Builder<Model>). Use whenever the user mentions a query builder, query scope, reusable query logic, or wants to extract complex queries out of controllers/models.
argument-hint: [what the user needs]
---

You're the **/query-builder** skill. Translate the user's query builder request into an enriched delegation to the `query-builder` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Builder class name** — `{Model}Builder`
- **Model** the builder extends from
- **Methods** to add (e.g., `paid()`, `forUser($userId)`, `overdue()`)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Builders/ 2>/dev/null
ls Modules/{Module}/app/Models/{Model}.php 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Model missing → flag: "Builder for `Bill` — model doesn't exist. Generate `/model` first?"
- Methods unclear → ask "Which scopes/methods do you want? (e.g., `paid()`, `overdue()`, `forUser($id)`)"
- Existing builder → confirm extend or replace

## Step 4: Build Context Blob

```
Context for query-builder agent:
- Module: {Module}
- Class: {Model}Builder
- Path: Modules/{Module}/app/Builders/{Model}Builder.php
- Extends: Illuminate\Database\Eloquent\Builder<{Model}>
- Methods: [paid(), overdue(), forUser(int $userId)]
- Model class to update (override newEloquentBuilder): Modules/{Module}/app/Models/{Model}.php
- Existing siblings: [BillBuilder.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:query-builder"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Builders/BillBuilder.php` (extends `Builder<Bill>`). Methods: `paid()`, `overdue()`, `forUser($id)`. Model updated to override `newEloquentBuilder()`. Usage: `Bill::query()->forUser($id)->overdue()`."

## When to Ask vs Assume

- Override `newEloquentBuilder()` in model → always
- Method return type `static` → always (for chaining)
