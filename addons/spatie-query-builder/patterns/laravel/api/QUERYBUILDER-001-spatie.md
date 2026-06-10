# QUERYBUILDER-001 — Filterable API queries (Spatie Query Builder)

Build Eloquent queries from **API request parameters** — filtering, sorting, including relations, and sparse fieldsets — with `spatie/laravel-query-builder`. The allow-lists are the **security boundary**: only what you explicitly permit is queryable.

## Install

```bash
composer require spatie/laravel-query-builder
```

## Request shape

```
GET /orders?filter[status]=open&filter[reference]=INV&sort=-created_at&include=customer&fields[orders]=id,status&page=2
```

`filter[x]=…` filters · `sort=-x` sorts (leading `-` = descending) · `include=rel` eager-loads · `fields[table]=a,b` sparse columns · `page` paginates.

## In a controller (the common case)

```php
use Spatie\QueryBuilder\QueryBuilder;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\AllowedInclude;
use Illuminate\Database\Eloquent\Builder;

public function index()
{
    $orders = QueryBuilder::for(Order::class)
        ->allowedFilters([
            'reference',                              // string entry = PARTIAL (LIKE %…%)
            AllowedFilter::exact('status'),           // exact; 'a,b' → IN, 'true' → bool
            AllowedFilter::exact('customer_id'),
            AllowedFilter::scope('placed_between'),    // drives scopePlacedBetween()
            AllowedFilter::callback('has_refund', fn (Builder $q) => $q->whereHas('refunds')),
        ])
        ->allowedSorts(['reference', 'total', 'created_at'])
        ->defaultSort('-created_at')                  // applied when no ?sort
        ->allowedIncludes(['customer', 'lines', AllowedInclude::count('linesCount')])
        ->allowedFields(['id', 'reference', 'status', 'total'])   // sparse fieldsets
        ->paginate(15)
        ->appends(request()->query());                // keep query string in pagination links

    return OrderResource::collection($orders);
}
```

## Filters in depth

- A plain string entry is a **partial** filter (`WHERE LOWER(col) LIKE %value%`).
- `AllowedFilter::exact('col')` — exact match; a comma list becomes `IN (...)`, `true`/`false` map to booleans.
- `AllowedFilter::partial('col')` / `AllowedFilter::beginsWithStrict('col')` — explicit partial / prefix.
- `AllowedFilter::scope('alias', 'scopeName')` — run a model scope from a query param.
- `AllowedFilter::callback('alias', fn (Builder $q, $value) => …)` — inline custom logic.
- `->default($value)` on an `AllowedFilter` applies a value when the param is absent.

## Sorts

```php
->allowedSorts(['created_at', AllowedSort::field('alias', 'db_column')])
->defaultSort('-created_at')   // '-' prefix = descending
```

## Includes

`allowedIncludes(['customer', 'lines'])` also enables `customerCount` / `customerExists` automatically; `AllowedInclude::count('ordersCount')` permits a count-only include. Nested includes use dot syntax (`include=lines.product`).

## Sparse fieldsets

`allowedFields(['id', 'reference'])` lets `?fields[orders]=id,reference` select only those columns. A field must be allow-listed before it (or a relation's fields) can be selected.

## Reusable / complex endpoints — a dedicated class

When an endpoint is reused or heavily configured, extend `QueryBuilder`:

```php
class OrdersQuery extends QueryBuilder
{
    public function __construct()
    {
        parent::__construct(Order::query(), request());
        $this->allowedFilters([/* … */])->allowedSorts([/* … */])->defaultSort('-created_at');
    }
}

// $orders = (new OrdersQuery())->paginate();
```

## Security

- The allow-lists **are** the boundary: a param not registered throws `InvalidFilterQuery` / `InvalidSortQuery` (HTTP 400) — it never silently runs. Never pass raw request input into `->where()`.
- `scope` / `callback` filters run your code — apply authorization inside them as you would anywhere.

## Don't

- Don't echo raw request params into the query — register each in the allow-lists.
- Don't use this for internal, non-API queries — a plain Eloquent query or a model scope is simpler.
- Don't confuse this with a custom Eloquent **builder** class (`newEloquentBuilder`) — that's an unrelated, core-Laravel concept.
