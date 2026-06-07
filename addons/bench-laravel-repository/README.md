# bench-laravel-repository

The **repository pattern** for teams that want to depend on an abstraction instead of
Eloquent directly. Core Bench prefers using Eloquent models straight from controllers and
services, so this is opinionated — hence an addon, not core.

## What it ships

- **`REPOSITORY-001-pattern`** pattern — a `{Model}Repository` interface, its Eloquent
  implementation, the container binding, and how controllers/services consume the
  interface.
- **`/repository`** skill + **`repository`** agent — generate the interface, the Eloquent
  implementation, and the binding for a given model.

## Install

```bash
bench addon add /path/to/bench/addons/bench-laravel-repository
bench rebuild
```

Then `/repository Order with find, paginate, create, update`.
