# HORIZON-001-queues

## Pattern

Laravel Horizon gives Redis-backed queues a code-driven supervisor config plus a dashboard for throughput, runtimes, tags, and failures. Use it when the app has more than a couple of background jobs, needs auto-scaling workers, or wants visibility into queue health. Horizon **replaces** running raw `queue:work`/Supervisor for the `redis` connection — you no longer hand-write worker process definitions.

Requires the `redis` queue connection (`QUEUE_CONNECTION=redis`). Horizon does not work with `database`/`sqs`/`beanstalk` drivers.

## Configuration (`config/horizon.php`)

Everything is code-driven and version-controlled — no per-server worker files. Publish with `php artisan horizon:install`, then shape these blocks:

```php
// config/horizon.php
use Illuminate\Support\Str;

return [
    'use'    => 'default',                 // Redis connection Horizon stores its own metadata on
    'prefix' => env(
        'HORIZON_PREFIX',
        Str::slug(env('APP_NAME', 'laravel'), '_').'_horizon:'
    ),
    'middleware' => ['web'],               // gate the dashboard — see "Securing the dashboard"

    'waits' => ['redis:default' => 60],    // LongWaitDetected fires past this many seconds

    'trim' => [                            // minutes to retain job records in Redis
        'recent'        => 60,
        'pending'       => 60,
        'completed'     => 60,
        'recent_failed' => 10080,          // 1 week
        'failed'        => 10080,
        'monitored'     => 10080,
    ],

    'metrics' => [
        'trim_snapshots' => ['job' => 24, 'queue' => 24],
    ],

    'memory_limit' => 64,                  // master supervisor RAM ceiling (MB)

    'defaults' => [
        'supervisor-1' => [
            'connection'          => 'redis',
            'queue'               => ['default'],
            'balance'             => 'auto',     // 'auto' | 'simple' | false
            'autoScalingStrategy' => 'time',     // 'time' | 'size'
            'maxProcesses'        => 1,
            'maxTime'             => 0,          // recycle a worker after N seconds (0 = unlimited)
            'maxJobs'             => 0,          // recycle a worker after N jobs (0 = unlimited)
            'memory'              => 128,
            'tries'               => 1,
            'timeout'             => 60,
            'nice'                => 0,
        ],
    ],

    'environments' => [                    // shallow-merged on top of defaults
        'production' => [
            'supervisor-1' => [
                'maxProcesses'    => 10,
                'balanceMaxShift' => 1,    // max workers added/removed per rebalance
                'balanceCooldown' => 3,    // seconds between rebalance decisions
            ],
        ],
        'local' => [
            'supervisor-1' => ['maxProcesses' => 3],
        ],
    ],
];
```

`environments` keys match `APP_ENV`. If the current env has no matching block, Horizon refuses to start — always define one per environment you deploy to (and `local` for dev).

## Queue naming + balancing

Split work across named queues by latency profile, then assign each to a supervisor. Don't dump everything on `default`.

```php
'defaults' => [
    'supervisor-1' => [          // fast, user-facing work
        'connection'   => 'redis',
        'queue'        => ['priority', 'default'],   // earlier = higher priority
        'balance'      => 'auto',
        'minProcesses' => 1,
        'maxProcesses' => 20,
    ],
    'supervisor-2' => [          // slow / heavy work, isolated so it can't starve the fast pool
        'connection'   => 'redis',
        'queue'        => ['heavy'],
        'balance'      => 'simple',
        'maxProcesses' => 4,
        'timeout'      => 300,
    ],
],
```

Queues within one supervisor's `queue` array are drained in order (leftmost first), giving priority.

**Balance strategies:**

| `balance` | Behavior |
|-----------|----------|
| `auto` | AutoScaler shifts workers between queues based on load. Pair with `autoScalingStrategy`. **Default choice.** |
| `simple` | Splits `maxProcesses` evenly across the supervisor's queues. |
| `false` | No balancing; each queue gets its own fixed pool. |

`autoScalingStrategy`: `time` weights by *avg runtime × queue size* (favors queues that take longer to clear); `size` weights by raw job count. Use `time` unless jobs are uniformly cheap. Tune `balanceMaxShift` (workers moved per cycle) and `balanceCooldown` (seconds between decisions) to damp thrashing.

## Job tags

Horizon auto-tags jobs with the IDs of any Eloquent models passed to the constructor (e.g. `App\Models\Order:42`). Add a `tags()` method for custom searchable/monitorable tags:

```php
public function tags(): array
{
    return ['tenant:'.$this->order->customer_id, 'fulfillment'];
}
```

Monitor a tag from the dashboard, or via the API (`POST /horizon/api/monitoring {"tag": "tenant:7"}`). Hide noisy jobs/tags from the completed list with `silenced` / `silenced_tags` in config.

> Job retry/timeout/queue conventions (attributes, `Queue::route()`, idempotency) are separate; this pattern covers only the Horizon-specific layer.

## Metrics

`metrics.trim_snapshots` sets how many hourly snapshots back the throughput/runtime graphs. Snapshots are captured by a scheduled command — register it so the dashboard graphs populate:

```php
// bootstrap/app.php (scheduling)
$schedule->command('horizon:snapshot')->everyFiveMinutes();
```

## Deployment

Horizon workers hold code in memory, so every deploy must restart them. The graceful path:

```bash
php artisan horizon:terminate
```

This tells the master supervisor to finish in-flight jobs, then exit — your process monitor (systemd / Supervisor / container orchestrator) restarts `php artisan horizon` with the new code. Run `horizon:terminate` as the **last** step of the deploy, after new code is in place.

- Keep `fast_termination => false` unless you accept brief double-running during the handoff.
- The OS process that runs `php artisan horizon` itself should be supervised (auto-restart on exit) — Horizon manages the *worker* processes, but something must keep the *master* alive.
- `php artisan horizon:pause` / `horizon:continue` halt/resume processing without killing workers (useful during migrations).

## Failed-job handling

- Failed jobs land in the dashboard's **Failed** tab with full payload + exception; retry individually or in bulk from there.
- CLI: `php artisan horizon:forget {id}` deletes one failed job; `--all` clears them.
- Implement `failed(\Throwable $e): void` on the job for terminal-failure side effects (alerting, marking a record failed) — same as any queued job.
- `recent_failed` / `failed` in `trim` control how long failures stay queryable.

## Securing the dashboard

The dashboard exposes job payloads — never leave it open in production. Gate it with a `Gate::define('viewHorizon', ...)` check in `App\Providers\HorizonServiceProvider::gate()`:

```php
// App\Providers\HorizonServiceProvider
protected function gate(): void
{
    Gate::define('viewHorizon', fn ($user) => $user->isAdmin());
}
```

The published `viewHorizon` gate applies via Horizon's auth middleware in every non-`local` environment.

For token- or IP-based access (e.g. no logged-in user), replace the gate with a custom callback in a service provider's `boot()`:

```php
use Laravel\Horizon\Horizon;

Horizon::auth(fn ($request) => app()->environment('local') || $request->user()?->isAdmin());
```

`worker recycling` (`maxTime`/`maxJobs` above) caps how long a worker runs before restarting — use it to bound memory leaks in long-lived workers.

## Key Points

- Requires `QUEUE_CONNECTION=redis`; replaces hand-rolled `queue:work` for that connection.
- Config is code-driven (`config/horizon.php`) and committed — define an `environments` block per `APP_ENV`.
- Name queues by latency profile; isolate heavy work on its own supervisor so it can't starve user-facing jobs.
- `balance => 'auto'` + `autoScalingStrategy => 'time'` is the sensible default.
- Add `tags()` for searchable monitoring; silence noisy ones in config.
- Schedule `horizon:snapshot` so metrics graphs populate.
- Deploy ends with `horizon:terminate`; supervise the master process for auto-restart.
- Always gate the dashboard with the `viewHorizon` gate.
