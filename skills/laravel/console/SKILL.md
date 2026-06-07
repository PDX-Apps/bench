---
description: Generate Laravel artisan console commands. Use whenever the user mentions a CLI command, scheduled task, cron job, console command, artisan command, or any code that should run from the terminal in a Laravel project, even if they don't explicitly say "console".
argument-hint: [what the user needs]
---

You're the **/console** skill. Parse the user's CLI-command request and delegate to the `console` agent.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Command class name** + **signature** (`namespace:verb`, e.g. `orders:purge-abandoned`)
- **Arguments + options** mentioned (`{--days=30}`, `{--dry-run}`)
- **What it does** — the Action/Service the command should delegate to
- **Scheduling** — one-off, or a cadence (daily/hourly/cron expression)

## Resolve Ambiguity

Ask only when a needed detail is missing or destructive intent is unclear:
- Scheduling unstated → "One-off command or scheduled (daily/hourly/cron)?"
- Destructive operation → confirm a `--dry-run` option is wanted (one line)
- The work belongs in an Action that doesn't exist yet → offer to run `/action` first

## Delegate

Use the Task tool with `subagent_type: "console"`, passing the parsed details.

## Synthesize

Report the result at the feature level: command path, final signature, what it delegates to, and the schedule (if any). Example:

> Created `app/Console/Commands/PurgeAbandonedOrdersCommand.php` with signature `orders:purge-abandoned {--days=30} {--dry-run}`, delegating to `PurgeAbandonedOrders`. Auto-registered. Scheduled daily in `routes/console.php` with `withoutOverlapping()`.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
