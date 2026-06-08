# REVERB-001-broadcasting

Broadcasting real-time events over Laravel Reverb (first-party WebSocket server):
implementing `ShouldBroadcast`, channel types and authorization, the Echo client
subscription, and Reverb server config.

## Pattern

### Broadcasting an event

An event must implement `ShouldBroadcast` (queued) or `ShouldBroadcastNow`
(synchronous, skips the queue). Define `broadcastOn()`, `broadcastAs()`, and
`broadcastWith()` on every broadcast event.

```php
<?php

declare(strict_types=1);

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

final class OrderShipped implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public readonly Order $order) {}

    /** @return array<int, Channel> */
    public function broadcastOn(): array
    {
        return [new PrivateChannel("orders.{$this->order->id}")];
    }

    public function broadcastAs(): string
    {
        return 'order.shipped';
    }

    /** @return array<string, mixed> */
    public function broadcastWith(): array
    {
        return [
            'id'     => $this->order->id,
            'status' => $this->order->status,
        ];
    }
}
```

Dispatch as any other Laravel event:

```php
OrderShipped::dispatch($order);
```

### Channel types

| Class | Auth needed | Use when |
|-------|-------------|----------|
| `Channel` | No | Truly public data (ticker, announcement) |
| `PrivateChannel` | Yes (boolean) | Per-user or per-tenant data |
| `PresenceChannel` | Yes (member array) | Collaborative rooms, who-is-online |

An event may broadcast on multiple channels by returning more than one element
from `broadcastOn()`.

### Channel authorization

Define authorizations in `routes/channels.php`. Return `true`/`false` for
private channels; return an array with member metadata for presence channels.

```php
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

// Private: only the order's owner may subscribe
Broadcast::channel('orders.{orderId}', function (User $user, int $orderId): bool {
    $order = Order::find($orderId);

    return $order !== null && $user->id === $order->user_id;
});

// Presence: return member info so the channel knows who is here
Broadcast::channel('rooms.{roomId}', function (User $user, int $roomId): array|false {
    // Return false to deny, or an array to grant + supply member data
    return ['id' => $user->id, 'name' => $user->name];
});
```

Laravel injects the authenticated user automatically from the request context.

### `ShouldBroadcast` vs `ShouldBroadcastNow`

| Interface | Dispatch path | Use when |
|-----------|--------------|----------|
| `ShouldBroadcast` | Queue worker | Default — keeps the request fast |
| `ShouldBroadcastNow` | Synchronous (in-request) | Latency is critical AND a queue worker isn't guaranteed |

Prefer `ShouldBroadcast` in all production setups that have a queue worker
running. `ShouldBroadcastNow` ties the WebSocket push to the HTTP request
cycle and will block under load.

### Client — Laravel Echo

Install the Echo client and the Reverb driver:

```bash
npm install laravel-echo pusher-js
```

Bootstrap Echo (typically in `resources/js/bootstrap.js`):

```js
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key:         import.meta.env.VITE_REVERB_APP_KEY,
    wsHost:      import.meta.env.VITE_REVERB_HOST,
    wsPort:      import.meta.env.VITE_REVERB_PORT ?? 8080,
    wssPort:     import.meta.env.VITE_REVERB_PORT ?? 443,
    forceTLS:    (import.meta.env.VITE_REVERB_SCHEME ?? 'https') === 'https',
    enabledTransports: ['ws', 'wss'],
});
```

#### Subscribing to channels

```js
// Private channel — note the leading '.' when broadcastAs() is used
Echo.private('orders.' + orderId)
    .listen('.order.shipped', (e) => {
        console.log('Order shipped:', e.id, e.status);
    });

// Public channel
Echo.channel('announcements')
    .listen('.announcement.posted', (e) => { /* … */ });

// Presence channel
Echo.join('rooms.' + roomId)
    .here((members) => { /* initial member list */ })
    .joining((member) => { /* member joined */ })
    .leaving((member) => { /* member left */ })
    .listen('.message.sent', (e) => { /* … */ });
```

> The leading `.` before the event name is required when you define
> `broadcastAs()`. Without it Echo looks for the fully-qualified class name.

#### Leaving a channel

```js
Echo.leaveChannel('orders.' + orderId);
Echo.leave('rooms.' + roomId); // also removes presence
```

### Reverb server config

Install and publish config:

```bash
composer require laravel/reverb
php artisan reverb:install
```

`.env`:

```dotenv
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=my-app-id
REVERB_APP_KEY=my-app-key
REVERB_APP_SECRET=my-app-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http

VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

Start the server (separate process from the web server and queue worker):

```bash
php artisan reverb:start
# With auto-reload in development:
php artisan reverb:start --debug
```

In production run Reverb as a long-lived daemon (Supervisor, systemd, etc.).
It is a standalone server process — not a PHP-FPM worker. Horizontal scaling
uses the `pulse` or Redis backend; see the Reverb docs for multi-server setup.

## Anti-Patterns

- **Fat payloads** — do not serialize the full Eloquent model into `broadcastWith()`.
  Send IDs and a minimal set of fields; let the client fetch details via an API
  endpoint if needed. Large payloads waste WebSocket bandwidth and leak data.
- **Public channel for private data** — use `PrivateChannel` (or `PresenceChannel`)
  for any per-user, per-tenant, or sensitive data. `Channel` has no auth gate.
- **`ShouldBroadcastNow` everywhere** — synchronous pushes tie every broadcast
  to the HTTP request cycle. This blocks workers, hurts response times, and
  loses the resilience of the queue. Reserve it for cases with no queue worker.
- **Hardcoding channel names client-side without matching server auth** — keep
  channel name templates consistent between `broadcastOn()` and `routes/channels.php`.
  A mismatch silently denies subscriptions.

## Key Points

- Implement `broadcastOn()`, `broadcastAs()`, and `broadcastWith()` on every broadcast event.
- `broadcastAs()` sets a stable wire name independent of the PHP class name; the Echo client must prefix it with `.`.
- Private and presence channel auth lives in `routes/channels.php` via `Broadcast::channel()`; the authenticated user is injected automatically.
- Default (`ShouldBroadcast`) dispatches through the queue — a queue worker must be running.
- Reverb runs as a separate long-lived process (`php artisan reverb:start`); set `BROADCAST_CONNECTION=reverb`.
- Keep `broadcastWith()` payloads minimal: IDs + a small set of display fields only.
