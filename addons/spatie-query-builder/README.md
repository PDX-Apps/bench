# spatie-query-builder

Build **filterable / sortable / includable API queries** from request parameters with [`spatie/laravel-query-builder`](https://spatie.be/docs/laravel-query-builder) — turn `?filter[status]=open&sort=-created_at&include=customer` into a safe Eloquent query, where the allow-lists are the security boundary.

## What it ships

- **`/query-builder`** skill + **`query-builder`** agent — wire `QueryBuilder::for({Model})` into a controller's `index` (or a reusable `{Model}Query` class) with the `allowedFilters` / `allowedSorts` / `allowedIncludes` / `allowedFields` you specify.
- **`QUERYBUILDER-001-spatie`** pattern — the full conventions: filter kinds (exact/partial/scope/callback), default sorts, includes + counts, sparse fieldsets, the reusable-class form, and the security model.

## Install

```bash
bench addon add spatie-query-builder
bench rebuild
```

Then, e.g.:

```
/query-builder Order index: filter status (exact) + reference (partial), sort created_at/total default -created_at, include customer + lines
```

> Not to be confused with a custom Eloquent **builder** class (`newEloquentBuilder`) — that's a different, core-Laravel concept covered by the core model patterns. This addon is specifically Spatie's request-driven query package.
