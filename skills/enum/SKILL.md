---
description: Generate a PHP 8.1 backed enum for status/type/mode fields. Use whenever the user mentions an enum, status type, role enum, or wants type-safe alternatives to string constants in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/enum** skill. Translate the user's enum request into an enriched delegation to the `enum` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Enum class name** — TitleCase + descriptive (`BillStatus`, `InvitationType`, `RecurrenceFrequency`)
- **Backing type**: string (default) or int
- **Cases**: list of TitleCase case names with values
- **Domain methods** suggested by request (`label()`, `color()`, `canTransitionTo()`)
- **Used in which model** (registered in `casts()`)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Enums/ 2>/dev/null
ls Modules/{Module}/app/Models/ 2>/dev/null  # model that uses it
```

## Step 3: Resolve Ambiguity

- Cases not specified → ask once with examples
- Domain methods → suggest `label()` for UI display, `color()` for status badges; ask if needed
- Used in migration enum column? → flag DB-001 enum vs string column tradeoffs

## Step 4: Build Context Blob

```
Context for enum agent:
- Module: {Module}
- Class: {Name}
- Path: Modules/{Module}/app/Enums/{Name}.php
- Backing type: string | int
- Cases:
    Pending = 'pending'
    Active = 'active'
    Completed = 'completed'
- Domain methods: [label(): string, color(): string, canTransitionTo(self $to): bool]
- Cast in model: Modules/{Module}/app/Models/{Model}.php → casts() method ['status' => {Name}::class]
- Existing siblings: [BillStatus.php, PaymentStatus.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:enum"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Enums/BillStatus.php` (string-backed: Unpaid, Partial, Paid, Skipped). Methods `label()`, `color()`. Registered in `Bill` model `casts()` method as `'status' => BillStatus::class`."

## When to Ask vs Assume

- Cases TitleCase → always
- Backing type → default string; int only when explicitly numeric
- Cast registration → assume yes if model exists
