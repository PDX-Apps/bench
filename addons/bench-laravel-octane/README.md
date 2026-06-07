# bench-laravel-octane

Safety guidance for running a Laravel app under **Octane** (FrankenPHP, Swoole, Open Swoole, or RoadRunner). Octane boots the framework **once** and feeds it many requests from a long-lived worker — so the request-per-process assumptions of PHP-FPM no longer hold. State and memory now persist across requests unless you reset them.

## What it ships

- **`OCTANE-001-safety`** pattern — the stateful-singleton / stale-request / memory-leak gotchas, what NOT to do, and the Octane-safe alternatives (`scoped` bindings, `flush`, method-injected `Request`, no growing static state).
- An **append** to the core **service** (`SERVICE-002-domain-services`) and **provider** (`PROVIDER-001-structure`) patterns — a short "Octane safety" note linking OCTANE-001, so anyone generating a service or provider sees the constraint.

## Install

```bash
bench addon add /path/to/bench/addons/bench-laravel-octane
bench rebuild
```
