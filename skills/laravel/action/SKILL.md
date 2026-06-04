---
description: Generate Laravel Action classes (single-purpose business operations) and domain Services (calculators, parsers, dispatchers). Use whenever the user describes a business operation like "create X", "send Y", "process Z", "calculate W", or any logic that doesn't belong in controllers or models in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/action** skill. Translate the user's business-logic request into an enriched delegation to the `action` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Class name** (`CreateBillAction`, `MarkBillPaidAction`, `BudgetCalculator`)
- **Type**: `action` (single `execute()`, side effects, dispatches events) OR `service` (utility, calculator, parser, dispatcher)
- **Inputs**: scalar params or DTO?
- **Side effects**: dispatches event? sends notification? calls another Action?

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Actions/ 2>/dev/null
ls Modules/{Module}/app/Services/ 2>/dev/null
ls Modules/{Module}/app/Data/ 2>/dev/null   # existing DTOs
ls Modules/{Module}/app/Events/ 2>/dev/null # existing events to dispatch
```

## Step 3: Resolve Ambiguity

- Action vs Service unclear → ask: "Action (single `execute()`, has side effects like persistence/events) or Service (calculator/parser/utility, multiple methods)?"
- DTO needed? If 4+ params or shape reused, suggest a DTO; otherwise inline params
- Event referenced doesn't exist → flag: "I'll wire to `BillCreated`. Doesn't exist yet — invoke `/event` first?"

## Step 4: Build Context Blob

```
Context for action agent:
- Module: {Module}
- Class: {Name}Action | {Name} (Service)
- Path: Modules/{Module}/app/{Actions|Services}/{Name}.php
- Type: action | service
- Existing siblings: [CreateBillAction.php, MarkBillPaidAction.php]
- Inputs: scalar params [int $billId, string $note] OR DTO {DtoName}
- Dependencies to inject: [AuthService, NotificationDispatcher]
- Events to dispatch: [BillCreated] (exists at Modules/Bill/app/Events/BillCreated.php)
- Calls other actions: [CreatePaymentAction]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:action"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Actions/MarkBillPaidAction.php`. Injects `AuthService` + `NotificationDispatcher`. Single `execute(int $billId)` method. Dispatches `BillPaid` event. Tests: pending — invoke `/unit-test`."

## When to Ask vs Assume

- "create X", "send Y", "process Z", "mark W" → almost always Action
- "calculate", "parse", "format", "client", "dispatcher" → almost always Service
- AuthService injection → assume YES for any action that needs current user
