---
description: Generate Laravel artisan console commands. Use whenever the user mentions a CLI command, scheduled task, cron job, console command, artisan command, or any code that should run from the terminal in a Laravel project, even if they don't explicitly say "console".
argument-hint: [what the user needs]
---

You're the **/console** skill. Translate the user's CLI command request into an enriched delegation to the `console` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Audit, Bill, etc.)
- **Command class name** (e.g., `CleanStaleJourneysCommand`, `BackfillBillStatusCommand`)
- **Command signature** — namespace + verb (e.g., `audit:clean-stale-journeys`)
- **Scheduling**: one-off? cron schedule (daily/hourly/etc.)?
- **Arguments + options** the user mentions (`{--days=30}`, `{--dry-run}`)
- **What it actually does** — should delegate to an existing Action/Service

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Console/ 2>/dev/null
ls Modules/{Module}/app/Actions/ 2>/dev/null    # action it might delegate to
ls Modules/{Module}/app/Services/ 2>/dev/null   # service it might use
cat routes/console.php 2>/dev/null              # existing schedules
```

## Step 3: Resolve Ambiguity

- Action/Service it delegates to is missing → flag: "Command should delegate work to an Action — none exists. Generate `/action` first?"
- Scheduling unclear → ask: "One-off command or scheduled (daily/hourly/cron expression)?"
- Destructive operation → assume `--dry-run` option needed; confirm in one line

## Step 4: Build Context Blob

```
Context for console agent:
- Module: {Module}
- Class: {Name}Command
- Path: Modules/{Module}/app/Console/{Name}Command.php
- Signature: {namespace}:{verb} {--option=default}
- Description: "..."
- Delegates to: Modules\{Module}\Actions\{ActionName} (exists at Modules/{Module}/app/Actions/{Name}.php)
- Options/arguments: [--days=30, --dry-run]
- Schedule: daily | hourly | cron("0 3 * * *") | none
- Existing siblings: [CleanStaleJourneysCommand.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:console"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Audit/app/Console/CleanStaleJourneysCommand.php` with signature `audit:clean-stale-journeys {--days=30} {--dry-run}`. Delegates to `JourneyCleanupService`. Auto-registered. Scheduled daily via `routes/console.php` with `withoutOverlapping()`."

## When to Ask vs Assume

- Auto-registration → assume yes (Laravel 12)
- Dependency injection in `handle()` → assume yes
- Exit codes (`Command::SUCCESS/FAILURE`) → always
- `--dry-run` for destructive ops → assume yes; confirm
