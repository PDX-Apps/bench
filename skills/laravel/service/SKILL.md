---
description: Generate a Laravel domain Service class (calculator, parser, dispatcher, client). Different from Action — Services are utilities with multiple methods, no required side effects. Use when the user describes a calculation, parser, formatter, or external client.
argument-hint: [what the user needs]
---

You're the **/service** skill. Translate the user's domain service request into an enriched delegation to the `service` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Currency, Notification, etc.)
- **Class name** — descriptive of purpose, NO `Service` suffix unless it's literally a generic "service" (`BudgetCalculator`, `NotificationDispatcher`, `StripeClient`, `MemberSplitResolver`)
- **Methods** — multiple related methods OK
- **Domain boundary** — should stay within one domain

⚠️ If the request is "create X", "send Y", "process Z" with side effects → that's an Action, suggest `/action` instead.

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Services/ 2>/dev/null
```

## Step 3: Resolve Ambiguity

- Generic name (`UserService`, `BillService`) → reject and propose specific name (`BudgetCalculator`, `MemberSplitResolver`)
- Has side effects (persists, dispatches events) → redirect to `/action`
- Stateful → push back, services should be stateless

## Step 4: Build Context Blob

```
Context for service agent:
- Module: {Module}
- Class: {DescriptiveName}  (NOT {Module}Service)
- Path: Modules/{Module}/app/Services/{Name}.php
- Methods: [calculate(int $amount, BillStatus $status): int, format(...)]
- Dependencies (constructor): [Calculator, Repository]
- Stateless: yes
- Existing siblings: [ChangeService.php, MemberSplitResolver.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:service"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Services/MemberSplitResolver.php`. Methods: `resolveDefaultSplits()`, `validateTotal()`, `applySplits()`. Stateless, no side effects. Use via constructor injection."

## When to Ask vs Assume

- Generic naming → reject and rename
- Stateless → enforce
- Side effects → redirect to /action
