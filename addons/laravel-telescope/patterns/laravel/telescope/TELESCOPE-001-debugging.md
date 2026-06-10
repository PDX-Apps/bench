# TELESCOPE-001 — Debug assistant (Laravel Telescope)

`laravel/telescope` is a local debug assistant — a dashboard over requests, queries, exceptions, jobs, logs, mail, cache, scheduled tasks, and more. It records a lot, so the two things that matter are **keeping it out of (or locked down in) production** and **not recording secrets**.

## Install (local-only is the safe default)

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

For a **local-only** install, stop Telescope from auto-registering and register it yourself only in `local`:

```jsonc
// composer.json
"extra": { "laravel": { "dont-discover": ["laravel/telescope"] } }
```

```php
// app/Providers/AppServiceProvider::register()
if ($this->app->environment('local')) {
    $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
    $this->app->register(\App\Providers\TelescopeServiceProvider::class);
}
```

## Authorization — the dashboard exposes everything; gate it

In **non-local** environments Telescope is only viewable to users the gate allows. Define it in the published `App\Providers\TelescopeServiceProvider`:

```php
protected function gate(): void
{
    Gate::define('viewTelescope', fn ($user) => $user->isAdmin());
}
```

For non-user (token/IP) access, replace the gate with `Telescope::auth()` in `boot()`:

```php
Telescope::auth(fn ($request) => app()->environment('local') || $request->user()?->isAdmin());
```

## Hide sensitive data

Telescope records request payloads and headers — redact secrets in the provider's `boot()`:

```php
Telescope::hideRequestParameters(['_token', 'password', 'password_confirmation']);
Telescope::hideRequestHeaders(['authorization', 'x-api-key', 'cookie']);
```

## Control volume — filter, tag, choose watchers

- **Filter** what gets recorded (essential in any non-trivial app / production):

  ```php
  Telescope::filter(function (IncomingEntry $entry) {
      if (app()->environment('local')) return true;
      return $entry->isReportableException() || $entry->isFailedRequest()
          || $entry->isFailedJob() || $entry->isSlowQuery() || $entry->hasMonitoredTag();
  });
  ```

- **Tag** entries for searchability: `Telescope::tag(fn (IncomingEntry $entry) => $entry->type === 'request' ? ['status:'.$entry->content['response_status']] : []);`
- **Watchers** live in `config/telescope.php`. Disable noisy ones and tune the `QueryWatcher` (`'slow' => 100` ms, `ignore_packages`, `ignore_paths`). The master switch is `'enabled' => env('TELESCOPE_ENABLED', true)`.

## Prune — the data grows fast

Schedule pruning so the `telescope_entries` tables don't balloon:

```php
// bootstrap/app.php (scheduling)
$schedule->command('telescope:prune')->daily();          // default keeps 24h
$schedule->command('telescope:prune --hours=48')->daily();
```

## Production

Telescope is a development tool. If you run it in production: set a strict **gate**, a recording **filter** (failed/slow/monitored only), **prune** aggressively, hide sensitive data, and gate the env with `TELESCOPE_ENABLED`. When in doubt, keep it off in production.

## Anti-patterns

- **Ungated dashboard** in a deployed env — it leaks every request, query, and payload. Always gate.
- **Recording secrets** — redact request params/headers (tokens, passwords, API keys, cookies).
- **No pruning** — `telescope_entries` bloats the DB; schedule `telescope:prune`.
- **All watchers on in production** — the recording overhead is real; filter and trim watchers.

## Key Points

- Install `--dev` and register only in `local` for a local-only setup; auto-discovery off via `dont-discover`.
- Gate the dashboard (`viewTelescope` / `Telescope::auth`) — it exposes everything.
- Hide sensitive request params + headers in the provider `boot()`.
- `Telescope::filter()` to limit what's recorded; `tag()` for searchable monitoring.
- Schedule `telescope:prune`; tune watchers (`QueryWatcher` slow threshold) in `config/telescope.php`.
