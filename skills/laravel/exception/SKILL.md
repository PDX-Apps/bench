---
description: Generate Laravel domain exception classes. Use whenever the user mentions a custom exception, error class, throwable, domain error (like "InvitationAlreadyProcessed", "InsufficientFunds"), or needs to model a business-rule violation as a typed exception in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/exception** skill. Translate the user's exception request into an enriched delegation to the `exception` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Household, Bill, etc.)
- **Exception class name** — `{Condition}Exception` (e.g., `InvitationAlreadyProcessedException`, `InsufficientFundsException`)
- **What it represents**: business-rule violation (DomainException) | runtime error | authorization failure (use Laravel's built-in instead)
- **Static factory method names** the user hints at (`forBill(...)`, `forUser(...)`)
- **Custom HTTP response needed?** (e.g., 409 Conflict instead of default 500)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Exceptions/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- 404/403/422/401 cases → Laravel's built-ins handle these. Confirm: "Laravel auto-handles 404/403/422/401 via standard exceptions. Are you sure you need a custom one, or do you want a different status?"
- Base class → assume `DomainException` for business rules; ask only if not obviously a domain rule
- Custom render() needed → only if HTTP status != 500. Ask if unclear.

## Step 4: Build Context Blob

```
Context for exception agent:
- Module: {Module}
- Class: {Name}Exception
- Path: Modules/{Module}/app/Exceptions/{Name}Exception.php
- Base class: DomainException | RuntimeException | other
- Static factories: [forBill(int $billId), forUser(int $userId)]
- HTTP response: default | custom (status: 409, body shape: {message, code})
- report() override: yes/no (custom logging channel?)
- Existing siblings: [InvitationAlreadyProcessedException.php]
- ⚠️ Compliance: NEVER include raw PII in exception messages (per DATA-001)
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:exception"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Household/app/Exceptions/InvitationAlreadyProcessedException.php` extending `DomainException`. Static factory `forInvitation(int $invitationId)`. Custom `render()` returns 409 with `{message, code: 'invitation_already_processed'}`. No PII in message (just the ID)."

## When to Ask vs Assume

- PII in messages → NEVER include; reject if user requests
- Standard HTTP cases → suggest Laravel built-ins instead of a custom exception
- Static factories → assume yes (project convention); discover names from context
