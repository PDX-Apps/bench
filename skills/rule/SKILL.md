---
description: Generate Laravel custom validation rule classes (implementing ValidationRule). Use whenever the user mentions a custom validator, business-rule validation that doesn't fit Laravel's built-in rules, or needs reusable validation logic across multiple FormRequests in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/rule** skill. Translate the user's validation rule request into an enriched delegation to the `rule` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Currency, Bill, etc.)
- **Rule class name** — descriptive, no `Rule` suffix needed (e.g., `ValidMoneyAmount`, `UniqueAcrossModules`)
- **What it validates** — the actual constraint
- **Cross-field?** Does it depend on other fields in the request? (→ implements `DataAwareRule`)
- **Configurable?** Does it take constructor arguments? (e.g., `new ValidCurrency('USD')`)
- **Used in** which FormRequest(s)?

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Rules/ 2>/dev/null
ls Modules/{Module}/app/Http/Requests/ 2>/dev/null  # FormRequests that may use it
```

## Step 3: Resolve Ambiguity

- Cross-field unclear → ask: "Does the rule need to read other fields from the request? (e.g., precision depends on currency field)"
- Constructor config → infer from request; if unclear, default to no-config

## Step 4: Build Context Blob

```
Context for rule agent:
- Module: {Module}
- Class: {Name}
- Path: Modules/{Module}/app/Rules/{Name}.php
- Cross-field: yes (implements DataAwareRule) | no
- Constructor params: [string $allowedOnly = null] | none
- Validation logic: brief description
- Error messages: [(:attribute) must be ...]
- Used by FormRequest(s): [Modules/.../Requests/CreateBillRequest.php]
- Existing siblings: [ValidCurrency.php, ValidMoneyAmount.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:rule"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Currency/app/Rules/ValidMoneyAmount.php` (implements `DataAwareRule, ValidationRule`). Reads `currency` field to determine precision. Use in FormRequest as `new ValidMoneyAmount()`."

## When to Ask vs Assume

- Implements `ValidationRule` (Laravel 12 contract, not deprecated `Rule`) → always
- Constructor config → infer; ask only when truly ambiguous
- Discovery of consuming FormRequests → check by grep, don't ask the user
