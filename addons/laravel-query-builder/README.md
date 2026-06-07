# bench-laravel-query-builder

Generate custom Eloquent **query builder classes** (`extends Builder<Model>`) — reusable, chainable query logic extracted out of controllers and models.

## What it ships

- **`/query-builder`** skill + **`query-builder`** agent — generate a `{Model}Builder` with chainable scope methods and wire `newEloquentBuilder()` on the model.

It reads the **core** `MODEL-002-query-builders` pattern, so there's no new pattern to maintain — the addon just adds the dedicated command.

## Install

```bash
bench addon add /path/to/bench/addons/laravel-query-builder
bench rebuild
```

Then `/query-builder Order with paid(), overdue(), forUser($id)`.
