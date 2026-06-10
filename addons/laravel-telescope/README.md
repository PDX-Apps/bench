# laravel-telescope

Set up and configure [Laravel Telescope](https://laravel.com/docs/telescope) — the local debug dashboard over requests, queries, exceptions, jobs, logs, and more — **safely**: local-only install, a locked-down dashboard gate, hidden sensitive data, recording filters, and scheduled pruning.

## What it ships

- **`/telescope`** skill + **`telescope`** agent — install Telescope (local-only by default) and wire the parts that are easy to get wrong: the `viewTelescope` authorization gate, `hideRequestParameters`/`hideRequestHeaders`, recording filters/tags, watcher tuning, and a `telescope:prune` schedule.
- **`TELESCOPE-001-debugging`** pattern — the conventions: install, gate/`Telescope::auth`, sensitive-data hiding, filter/tag, `config/telescope.php` watchers, pruning, and production guidance.

## Install

```bash
bench addon add laravel-telescope
bench rebuild
```

Then, e.g.:

```
/telescope install local-only, gate the dashboard to admins, hide auth headers, prune daily
```

> Sibling to **laravel-horizon** (queues dashboard). Telescope is a development tool — keep it out of, or strictly locked down in, production.
