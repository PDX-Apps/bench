# SCOUT-001 — Making a Model Searchable (Laravel Scout)

Add full-text search to an Eloquent model: the `Searchable` trait, the indexed
payload, index config, search queries, conditional/queued indexing, and driver
choice.

## Install

```bash
composer require laravel/scout
php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"
```

Pick a driver in `.env` (`database` needs no external service and is the
simplest place to start; `meilisearch`/`typesense` are self-hostable;
`algolia` is hosted):

```dotenv
SCOUT_DRIVER=database
SCOUT_QUEUE=true
SCOUT_PREFIX=myapp_

# meilisearch
MEILISEARCH_HOST=http://localhost:7700
MEILISEARCH_KEY=masterKey
```

## The Searchable trait

Add `Searchable` to the model. Override `toSearchableArray()` to define exactly
what gets indexed — keep it lean (don't dump the whole row), cast dates to
timestamps, and include only fields you search or filter on.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Laravel\Scout\Searchable;

class Order extends Model
{
    use Searchable;

    // Index name (defaults to the table name, prefixed by scout.prefix)
    public function searchableAs(): string
    {
        return 'orders_index';
    }

    public function toSearchableArray(): array
    {
        return [
            'id'         => $this->id,
            'reference'  => $this->reference,
            'notes'      => $this->notes,
            'status'     => $this->status,
            'customer_id'=> $this->customer_id,
            'created_at' => $this->created_at->timestamp,
        ];
    }
}
```

`id` should map to the model key so engines hydrate the right records.

## Conditional indexing

Skip records that shouldn't appear in results (drafts, soft-deleted, etc.):

```php
public function shouldBeSearchable(): bool
{
    return $this->status === 'completed';
}
```

Eager-load relations during bulk import to avoid N+1:

```php
public function makeAllSearchableUsing($query)
{
    return $query->with('customer');
}
```

## Queued indexing

Set `SCOUT_QUEUE=true` (`config('scout.queue')`) so index writes happen on a
worker instead of blocking the request. Run a queue worker in production.

## database driver: column strategy

With the `database` driver, attributes on `toSearchableArray()` pick how each
column is matched — full-text index vs. prefix `LIKE`:

```php
use Laravel\Scout\Attributes\SearchUsingFullText;
use Laravel\Scout\Attributes\SearchUsingPrefix;

#[SearchUsingPrefix(['reference'])]
#[SearchUsingFullText(['notes'])]
public function toSearchableArray(): array
{
    return ['reference' => $this->reference, 'notes' => $this->notes];
}
```

## Searching

```php
Order::search('widget')->get();
Order::search('widget')->where('status', 'completed')->get();
Order::search('widget')->orderByDesc('created_at')->paginate(15);
```

In a controller:

```php
public function index(Request $request)
{
    $orders = Order::search($request->input('q', ''))
        ->where('status', 'completed')
        ->paginate(12);

    return OrderResource::collection($orders);
}
```

`paginate()` is length-aware (page numbers); `simplePaginate()` is prev/next
only. `where()` is exact-match filtering, not SQL — the engine handles it.

## Indexing from the CLI

```bash
php artisan scout:import "App\Models\Order"
php artisan scout:import "App\Models\Order" --fresh
php artisan scout:flush  "App\Models\Order"
```

## Meilisearch / Typesense index settings

Declare filterable/sortable attributes in `config/scout.php`, then sync:

```php
'meilisearch' => [
    'index-settings' => [
        'orders_index' => [
            'filterableAttributes' => ['status', 'customer_id'],
            'sortableAttributes'   => ['created_at'],
        ],
    ],
],
// php artisan scout:sync-index-settings
```

`where()`/`orderBy()` only work on attributes the engine is configured to
filter/sort on — declare them or the query silently returns nothing.

## Rules

- Keep `toSearchableArray()` lean; index only what you search or filter on.
- Map `id` to the model key; cast dates to timestamps.
- Use `shouldBeSearchable()` to keep drafts/unpublished rows out of the index.
- Queue indexing (`SCOUT_QUEUE=true`) in production; run a worker.
- For Meilisearch/Typesense, declare filterable/sortable attributes before filtering/sorting on them.
- After changing the searchable payload, re-import (`scout:import --fresh`).
