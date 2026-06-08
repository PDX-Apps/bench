# laravel-pennant

Laravel **Pennant** feature flags — class-based and closure features, scope-aware checks, gradual rollouts, and Blade/middleware integration.

## What it ships

- **`/feature`** skill + **`feature`** agent — define a feature flag (class-based or closure), wire `Feature::active` checks, add `@feature` Blade directives, or protect routes with `->middleware('features:flag-name')`.
- **`PENNANT-001-features`** — the full pattern: defining features, scopes (per-user, per-team, global), rich values, eager loading, lifecycle cleanup, and anti-patterns.

## Install

```bash
bench addon add laravel-pennant
bench rebuild
```

Then: `/feature new-checkout scoped to user, class-based, add @feature blade directive`.

## Requires (in the target project)

```bash
composer require laravel/pennant
php artisan vendor:publish --tag="pennant-migrations"
php artisan migrate
```

## Scopes + Blade

- Default scope is the authenticated user; use `Feature::for($team)` for team-scoped flags or `Feature::for(null)` for global toggles.
- `@feature('flag-name') ... @endfeature` works in any Blade view.
- Route middleware: `->middleware('features:flag-name')`.
