# laravel-reverb

Real-time broadcasting over **laravel/reverb** — Laravel's first-party WebSocket server.

## What it ships

- **`/broadcast`** skill + **`broadcast`** agent — create or extend a broadcast event with `ShouldBroadcast`, register the channel and authorization in `routes/channels.php`, and surface the matching Echo client subscription.
- **`REVERB-001-broadcasting`** — event anatomy (`broadcastOn/As/With`), channel types (public / private / presence), channel authorization, Echo client subscription, Reverb server config, and anti-patterns.

## Install

```bash
bench addon add laravel-reverb
bench rebuild
```

Then: `/broadcast OrderShipped on a private channel for the order owner, payload is id + status`.

## Requires (in the target project)

```bash
composer require laravel/reverb
php artisan reverb:install
npm install laravel-echo pusher-js
```

`.env`: `BROADCAST_CONNECTION=reverb` + `REVERB_APP_ID`, `REVERB_APP_KEY`, `REVERB_APP_SECRET`, `REVERB_HOST`, `REVERB_PORT`.

Run the Reverb server as a separate long-lived process:

```bash
php artisan reverb:start
```

A queue worker must also be running for `ShouldBroadcast` events (default).
