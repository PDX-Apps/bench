---
description: Generate Laravel queued Jobs (background work, async processing, deferred tasks). Use whenever the user mentions a queued job, background task, async operation, batch processing, dispatching work to a queue, or anything that should run outside the request cycle in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/job** skill. Translate the user's background-work request into an enriched delegation to the `job` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Audit, Bill, etc.)
- **Job class name** (`SendBillReminderJob`, `RecordChangeJob`)
- **What it does** — should delegate to an Action
- **Inputs**: scalar IDs only (NEVER models)
- **Where it gets dispatched FROM** (controller? action? scheduled command?)

⚠️ If the user describes "react to event X" with "do Y in background", that's a queued LISTENER not a Job. Suggest `/listener` (or `/event` for both) instead.

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Jobs/ 2>/dev/null
ls Modules/{Module}/app/Actions/ 2>/dev/null  # action it likely delegates to
cat config/audit.php 2>/dev/null | head -20   # queue config if module has one
```

## Step 3: Resolve Ambiguity

- Job vs queued listener → see warning above; if no event involved, it's a Job
- Action it delegates to missing → flag: "Generate `/action` first?"
- Tries/timeout config → assume `tries=3`, default timeout; confirm if request implies otherwise
- Custom queue → check module's config for a queue name (e.g., `audit.queue`); use it

## Step 4: Build Context Blob

```
Context for job agent:
- Module: {Module}
- Class: {Name}Job
- Path: Modules/{Module}/app/Jobs/{Name}Job.php
- Constructor inputs: [int $billId, int $userId]   # IDs only
- Delegates to: Modules\{Module}\Actions\{ActionName} (injected in handle())
- Tries: 3
- Timeout: 60 (default) | custom
- Queue: default | from config('{module}.queue')
- Idempotency strategy: check if already processed
- Dispatched from: [Modules/Bill/Controllers/BillController@store, ...]
- Existing siblings: [RecordChangeJob.php, RecordActivityJob.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:job"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Audit/app/Jobs/RecordChangeJob.php`. Constructor takes `string $type, int $id, string $event` (IDs/scalars only). `handle()` injects `RecordChangeAction`. `tries=3`, queue from `config('audit.queue')`. Idempotency via existing-record check. Dispatched as `RecordChangeJob::dispatch(...)` from your action layer."

## When to Ask vs Assume

- IDs not models → never ask, always IDs
- Default tries=3 → assume; confirm only if user specifies
- Idempotency → always include; suggest a strategy based on context
