# CONSOLE-001-commands

## Pattern

Artisan console commands for CLI operations: scheduled tasks, one-off maintenance, data migrations, debugging utilities.

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Actions\PurgeAbandonedOrders;
use Illuminate\Console\Command;

class PurgeAbandonedOrdersCommand extends Command
{
    protected $signature = 'orders:purge-abandoned
                            {--days=30 : Orders abandoned longer than this many days are removed}
                            {--dry-run : Show what would be removed without deleting}';

    protected $description = 'Remove abandoned orders older than the specified number of days';

    public function handle(PurgeAbandonedOrders $purge): int
    {
        $days = (int) $this->option('days');
        $dryRun = (bool) $this->option('dry-run');

        $count = $purge->handle(days: $days, dryRun: $dryRun);

        $this->info($dryRun
            ? "Would remove {$count} abandoned orders (dry run)."
            : "Removed {$count} abandoned orders."
        );

        return self::SUCCESS;
    }
}
```

## Auto-Registration (Laravel 13)

Commands in `app/Console/Commands/` auto-register — no manual registration needed. `make:command` places them correctly.

To verify:
```bash
php artisan list --no-interaction | grep orders:
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

Schedule in `routes/console.php` (Laravel 13):

```php
use Illuminate\Support\Facades\Schedule;

Schedule::command('orders:purge-abandoned --days=30')
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

## Key Points

- Live in `app/Console/Commands/`; naming `{Verb}{Noun}Command` (e.g., `PurgeAbandonedOrdersCommand`, `SeedTestDataCommand`)
- Auto-registered in Laravel 13 — no manual registration
- Signature uses `namespace:command-name` (e.g., `orders:purge-abandoned`)
- Inject Actions/Services via the `handle()` signature — the container resolves them
- Return explicit exit codes (`Command::SUCCESS` / `FAILURE` / `INVALID`)
- Provide a `--dry-run` option for destructive commands, and keep `--no-interaction`-safe defaults for AI/CI invocation
- Schedule in `routes/console.php` or via a `schedule()` method on the command; add `withoutOverlapping()` + `onOneServer()` for scheduled commands
- `declare(strict_types=1)` recommended
