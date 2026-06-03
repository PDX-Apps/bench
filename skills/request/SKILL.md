---
description: Generate a Laravel FormRequest class for input validation. Use when the user wants ONLY a FormRequest (not the full HTTP stack). For full HTTP layer (controller+request+resource+route), use /api instead.
argument-hint: [what the user needs]
---

You're the **/request** skill. Translate the user's FormRequest into an enriched delegation to the `request` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **FormRequest class name** — `{Action}{Model}Request` (e.g., `CreatePersonalBillRequest`, `UpdateInvitationRequest`)
- **Fields + rules** mentioned (`amount: required|numeric|gt:0`)
- **DTO**: should `toDto()` method emit a DTO? (yes for 4+ params or shape reused; no for one-off)
- **Custom validation rules** referenced (e.g., `ValidMoneyAmount`)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Http/Requests/ 2>/dev/null
ls Modules/{Module}/app/Data/ 2>/dev/null   # existing DTOs
ls Modules/{Module}/app/Rules/ 2>/dev/null  # custom rules referenced
```

Read one sibling FormRequest to see array vs string rule style:
```bash
head -40 Modules/{Module}/app/Http/Requests/$(ls Modules/{Module}/app/Http/Requests/ 2>/dev/null | head -1) 2>/dev/null
```

## Step 3: Resolve Ambiguity

- DTO needed? → 4+ params or used outside this request → yes; otherwise no
- Custom rule referenced doesn't exist → flag: "Rule `ValidMoneyAmount` doesn't exist. Generate `/rule` first?"
- Rule style (array vs string) → match siblings (don't ask)

## Step 4: Build Context Blob

```
Context for request agent:
- Module: {Module}
- Class: {Action}{Model}Request
- Path: Modules/{Module}/app/Http/Requests/{Name}Request.php
- Fields + rules:
    name: required, string, max:100
    amount: required, numeric, ValidMoneyAmount
    currency: required, ValidCurrency
- Rule style observed in siblings: array | string
- Custom rule classes referenced: [ValidMoneyAmount, ValidCurrency] (existing paths)
- toDto(): yes (DTO: BillData) | no
- Custom error messages: [...]
- Existing siblings: [CreatePersonalBillRequest.php, UpdateBillRequest.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:request"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Http/Requests/CreatePersonalBillRequest.php`. 8 rules + 5 custom error messages. `toDto()` returns `BillData`. Matches sibling array-style rule format."

## When to Ask vs Assume

- Sibling style → match silently
- Custom error messages → include if user mentioned UX or for non-standard rules; otherwise rely on Laravel defaults
- `authorize()` method → return `true` (authorization is in controller/route, not request)
