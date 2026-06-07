# bench-horizon

Laravel **Horizon** conventions for Redis-backed queues — code-driven supervisor configuration, queue balancing, job tags, metrics, and zero-downtime deployment.

## What it ships

- **`HORIZON-001-queues`** pattern — `config/horizon.php` supervisors, queue naming + balancing (`auto`/`simple`), `autoScalingStrategy`, job `tags()`, metrics snapshots, deployment via `horizon:terminate`, failed-job handling, and securing the dashboard.
- An **append** to the core **JOB** pattern — adds a short "Horizon" note (tags + queue assignment) linking to HORIZON-001, so anyone generating a job sees the Horizon conventions when the addon is active.

Horizon is mostly configuration, so this addon ships patterns rather than a command — the existing `/job` skill covers job generation, now Horizon-aware.

## Install

```bash
bench addon add /path/to/bench/addons/bench-horizon
bench rebuild
```

Requires `QUEUE_CONNECTION=redis` in the target project.
