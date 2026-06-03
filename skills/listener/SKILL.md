---
description: Generate ONE Laravel event listener (sync or queued). Use when adding a listener that reacts to an event. For events themselves, use /event.
argument-hint: [what the user needs]
---

You're the **/listener** skill. Translate the user's listener request into an enriched delegation to the `listener` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Notification, etc.) — listener lives in the SUBSCRIBING module
- **Listener class** — `{Verb}{Object}Listener` (e.g., `SendBillCreatedNotificationListener`)
- **Event** it reacts to (FQCN) — must already exist
- **Type**: sync (< 100ms, critical side effect) OR queued (slow, external API; default)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Listeners/ 2>/dev/null
grep -rln "class {EventClassName}" Modules/ --include="*.php" 2>/dev/null  # confirm event exists
```

## Step 3: Resolve Ambiguity

- Event missing → flag: "Listener for `BillCreated` — event doesn't exist. Generate `/event` first?"
- Sync vs queued → assume queued; only sync for fast critical (cache invalidation, audit log)
- Cross-module placement → confirm: "Listener subscribes to `Bill\Events\BillCreated` but lives in `Notification` module. Correct placement?"

## Step 4: Build Context Blob

```
Context for listener agent:
- Module: {Module}  (subscribing module)
- Class: {Name}Listener
- Path: Modules/{Module}/app/Listeners/{Name}Listener.php
- Event: \Modules\Bill\app\Events\BillCreated (path)
- Type: sync | queued (default queued)
- Re-fetch model in handle(): use $event->billId → Bill::findOrFail()
- Idempotency check: yes (queued may retry)
- Existing siblings: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:listener"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Notification/app/Listeners/SendBillCreatedNotificationListener.php` (queued). Re-fetches Bill from `$event->billId`. Idempotency check via `notification.already_sent`. Auto-discovered."

## When to Ask vs Assume

- Pass IDs not models in events → expect this from event side; never re-introduce model serialization
- Default queued → only sync for fast critical
- Idempotency for queued → always include
