---
mode: append
---

## Horizon

If the project runs **Laravel Horizon** (Redis queues + dashboard), two extra conventions apply to queued jobs:

- **Tags** — add a `tags(): array` method to surface searchable/monitorable tags in the dashboard. Models passed to the constructor are auto-tagged (`App\Models\Order:42`); `tags()` adds custom ones (e.g. `['tenant:'.$this->order->customer_id, 'fulfillment']`).
- **Queue assignment** — name queues by latency profile (`priority`, `default`, `heavy`) and let Horizon's supervisors balance them, rather than scattering ad-hoc `onQueue()` calls. Route via `Queue::route()` in a provider as usual.

See `<PLUGIN_ROOT>/patterns-built/laravel/horizon/HORIZON-001-queues.md` for supervisor config, balancing strategies, metrics, deployment (`horizon:terminate`), and failed-job handling.
