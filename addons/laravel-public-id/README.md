# laravel-public-id

Expose **ULID public identifiers** in your API while keeping fast auto-increment integer primary keys internally — preventing resource enumeration without sacrificing join/index performance.

## What it does

Layers (`append` mode) public-ID guidance onto three core patterns, so generated code is consistent:

- **MODEL-001** — `public_id` auto-generated in `booted()`, `getRouteKeyName()` → `public_id`, never mass-assigned.
- **MIGRATION-001** — a unique `ulid('public_id')` column alongside `id()`.
- **RESOURCE-001** — API resources expose `public_id` as `id`; the internal `id` is never serialized.

## Install

```bash
bench addon add laravel-public-id
bench rebuild
```

## Why

Auto-increment IDs in URLs let anyone enumerate your resources (`/orders/1`, `/orders/2`, …). ULIDs are unguessable and sortable (timestamp-prefixed), while the integer `id` keeps relationships and indexes fast.
