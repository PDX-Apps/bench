# bench-scout

Laravel **Scout** full-text search — the `Searchable` trait, `toSearchableArray()`, index/driver configuration, search queries with filtering & pagination, and conditional/queued indexing across the Algolia / Meilisearch / Typesense / database drivers.

## What it ships

- **`/scout`** skill + **`scout`** agent — make a model `Searchable` and build search endpoints.
- **`SCOUT-001-searchable`** — the `Searchable` trait, the indexed payload, `shouldBeSearchable()`, queued indexing, driver choice, search queries + pagination, and CLI re-indexing.

## Install

```bash
bench addon add /path/to/bench/addons/bench-scout
bench rebuild
```

Then `/scout make Order searchable on reference + notes, only when completed, with a /orders/search endpoint`.

## Requires (in the target project)

```bash
composer require laravel/scout
php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"
```

`.env`: `SCOUT_DRIVER` (`database` to start; `meilisearch` / `typesense` / `algolia` otherwise) + that driver's credentials. After making a model searchable, run `php artisan scout:import "App\Models\Order"`.
