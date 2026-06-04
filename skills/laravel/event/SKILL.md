---
description: Generate Laravel domain events and listeners (sync or queued). Use whenever the user describes something happening that other parts of the system should react to — "when X happens, Y should occur" — or mentions events, listeners, observers, broadcasting, or pub/sub patterns in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/event** skill. Translate the user's event-driven request into an enriched delegation to the `event` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Event name** in past tense (`BillCreated`, `MemberInvited`) OR detected/future tense
- **Listener(s)** (often paired): `SendBillCreatedNotificationListener`, `LogBillCreationListener`
- **Listener type**: sync (< 100ms, critical side effect) OR queued (slow, external API, default)
- **Payload**: which IDs to pass (NEVER models — IDs only)

⚠️ If the user says "send X in the background" with no event involved, this is a JOB not an event/listener. Suggest `/job` instead.

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Events/ 2>/dev/null
ls Modules/{Module}/app/Listeners/ 2>/dev/null
ls Modules/{Module}/app/Actions/ 2>/dev/null  # actions are where events get dispatched FROM
```

## Step 3: Resolve Ambiguity

- Event vs Job confusion → see warning above; if user's request is "trigger X automatically when Y happens", that's event+listener
- Sync vs queued listener → assume queued unless the listener does only fast critical work (audit log update, cache invalidation)
- Cross-module listener (BillCreated → NotificationModule listener) → confirm placement (the listener lives in the SUBSCRIBING module, not the publishing one)

## Step 4: Build Context Blob

```
Context for event agent:
- Module: {Module}
- Event class: {Name}
- Path: Modules/{Module}/app/Events/{Name}.php
- Trigger: dispatched from {Module}\Actions\{ActionName}::execute()
- Payload: [int $billId, int $userId]   # IDs only
- Listener(s) needed: [
    {Module}\Listeners\{ListenerName} (queued, sends notification)
  ]
- Existing events in module: [BillCreated.php, BillPaid.php]
- Existing listeners: []
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:event"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Events/BillPaid.php` (`final readonly`, `SerializesModels`, payload: `int $billId, int $paidByUserId`). Created `Modules/Bill/app/Listeners/SendBillPaidNotificationListener.php` (queued, re-fetches Bill from `$event->billId`). Dispatch from `MarkBillPaidAction::execute()`."

## When to Ask vs Assume

- Sync vs queued → default queued, only sync for fast critical side effects
- Pass IDs not models → never ask, always IDs (project rule)
- Event name tense → past for completed actions, "Will" for scheduled, "Detected" for observed
