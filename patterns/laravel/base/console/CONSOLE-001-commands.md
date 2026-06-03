# CONSOLE-001-commands

## Pattern

Artisan console commands for CLI operations: scheduled tasks, one-off maintenance, data migrations, debugging utilities.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Audit\Console;

use Illuminate\Console\Command;
use Modules\Audit\Services\JourneyCleanupService;

class CleanStaleJourneysCommand extends Command
{
    protected $signature = 'audit:clean-stale-journeys
                            {--days=30 : Journeys older than this many days are removed}
                            {--dry-run : Show what would be removed without deleting}';

    protected $description = 'Remove audit journeys older than the specified number of days';

    public function handle(JourneyCleanupService $cleanup): int
    {
        $days = (int) $this->option('days');
        $dryRun = (bool) $this->option('dry-run');

        $count = $cleanup->run(days: $days, dryRun: $dryRun);

        $this->info($dryRun
            ? "Would remove {$count} stale journeys (dry run)."
            : "Removed {$count} stale journeys."
        );

        return self::SUCCESS;
    }
}
```

## Auto-Registration (Laravel 12)

Commands auto-register from `Modules/{Module}/app/Console/`. No manual registration needed — `module:make-command` places them correctly.

To verify:
```bash
php artisan list --no-interaction | grep audit:
```

## Signature Syntax

```php
protected $signature = 'namespace:command-name
                        {required-arg : Description}
                        {optional-arg? : Description}
                        {arg-with-default=value : Description}
                        {*variadic-args : Description}
                        {--flag : Boolean flag}
                        {--option= : Option requiring value}
                        {--option-with-default=foo : Option with default}
                        {--shortcut|s : Short flag}';
```

## Scheduling

Schedule in `routes/console.php` (Laravel 12):

```php
use Illuminate\Support\Facades\Schedule;

Schedule::command('audit:clean-stale-journeys --days=30')
    ->daily()
    ->onOneServer()
    ->withoutOverlapping();
```

Or via the command itself:

```php
public function handle(): int { /* ... */ }

public function schedule(Schedule $schedule): void
{
    $schedule->command(static::class)->daily();
}
```

## Output Conventions

- `$this->info('...')` — green (success messages)
- `$this->warn('...')` — yellow (warnings)
- `$this->error('...')` — red (errors)
- `$this->line('...')` — plain
- `$this->table($headers, $rows)` — tabular output
- `$this->newLine()` — blank line

Return codes:
- `Command::SUCCESS` (0) — success
- `Command::FAILURE` (1) — generic failure
- `Command::INVALID` (2) — invalid input

## Confirmations + Prompts

Skip in `--no-interaction` mode (used by AI agents and CI):

```php
if (!$this->confirm('Really delete?', default: false)) {
    return self::FAILURE;
}
```

`confirm()` returns the default in non-interactive mode.

## Rules

- Live in `Modules/{Module}/app/Console/`
- Naming: `{Verb}{Noun}Command` (e.g., `CleanStaleJourneysCommand`, `SeedTestDataCommand`)
- Signature uses `module-namespace:command-name` (e.g., `audit:clean-stale-journeys`)
- Inject Actions/Services via `handle()` signature — Laravel resolves them
- Return explicit exit codes (`Command::SUCCESS` / `FAILURE`)
- Provide a `--dry-run` option for destructive commands
- Use `withoutOverlapping()` and `onOneServer()` for scheduled commands
- Strict types via `declare(strict_types=1)` recommended

## Key Points

- Auto-registered in Laravel 12 — no manual registration
- Schedule in `routes/console.php` or via `schedule()` method on the command
- Use `--dry-run` for destructive operations
- Inject dependencies in `handle()` (Laravel's container resolves them)
- Always return explicit exit codes
- Use `withoutOverlapping()` for scheduled commands to prevent concurrent runs
- Use `--no-interaction`-safe defaults for AI-invoked commands
