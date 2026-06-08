# REPOSITORY-001-pattern

## Pattern

A **repository** hides Eloquent behind a per-model interface. Controllers and services
depend on the interface; a single Eloquent implementation does the querying; the container
binds one to the other. This decouples consumers from the persistence layer and gives you a
seam to mock in tests or swap the backing store.

> Opinionated: core Bench uses Eloquent directly from controllers/services. Adopt this
> pattern when a team has explicitly chosen it — apply it consistently, not selectively.

## Structure

### 1. Interface (the contract consumers depend on)

```php
<?php

declare(strict_types=1);

namespace App\Repositories\Contracts;

use App\Models\Order;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface OrderRepositoryInterface
{
    public function find(int $id): ?Order;

    /** @return Collection<int, Order> */
    public function all(): Collection;

    public function paginate(int $perPage = 15): LengthAwarePaginator;

    /** @param array<string, mixed> $attributes */
    public function create(array $attributes): Order;

    /** @param array<string, mixed> $attributes */
    public function update(Order $order, array $attributes): Order;

    public function delete(Order $order): void;
}
```

### 2. Eloquent implementation

```php
<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Models\Order;
use App\Repositories\Contracts\OrderRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

final class EloquentOrderRepository implements OrderRepositoryInterface
{
    public function find(int $id): ?Order
    {
        return Order::find($id);
    }

    /** @return Collection<int, Order> */
    public function all(): Collection
    {
        return Order::all();
    }

    public function paginate(int $perPage = 15): LengthAwarePaginator
    {
        return Order::query()->latest()->paginate($perPage);
    }

    /** @param array<string, mixed> $attributes */
    public function create(array $attributes): Order
    {
        return Order::create($attributes);
    }

    /** @param array<string, mixed> $attributes */
    public function update(Order $order, array $attributes): Order
    {
        $order->update($attributes);

        return $order;
    }

    public function delete(Order $order): void
    {
        $order->delete();
    }
}
```

### 3. Container binding (in a service provider)

```php
<?php

declare(strict_types=1);

namespace App\Providers;

use App\Repositories\Contracts\OrderRepositoryInterface;
use App\Repositories\EloquentOrderRepository;
use Illuminate\Support\ServiceProvider;

final class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->bind(OrderRepositoryInterface::class, EloquentOrderRepository::class);
    }
}
```

Reuse an existing provider (e.g. `AppServiceProvider`) instead of creating one if the
project keeps bindings there. For many repositories, a `$bindings` array on the provider is
cleaner than repeated `bind()` calls.

### 4. How consumers depend on it

Type-hint the **interface** — the container resolves the Eloquent implementation. Never
reference the concrete class outside the binding.

```php
final class OrderController extends Controller
{
    public function __construct(
        private readonly OrderRepositoryInterface $orders,
    ) {}

    public function show(int $id): OrderResource
    {
        $order = $this->orders->find($id) ?? abort(404);

        return new OrderResource($order);
    }
}
```

A service consumes it the same way:

```php
final class CancelOrder
{
    public function __construct(
        private readonly OrderRepositoryInterface $orders,
    ) {}

    public function handle(int $id): Order
    {
        $order = $this->orders->find($id) ?? throw new OrderNotFoundException();

        return $this->orders->update($order, ['status' => 'cancelled']);
    }
}
```

## Why

- Consumers depend on an abstraction, so the persistence implementation can change without
  touching them.
- The interface is a clean mock/fake seam in tests.
- Query logic for a model lives in one place instead of being scattered across controllers.

## Notes

- Keep one repository per aggregate/model; don't build a generic "do everything" base
  repository that leaks Eloquent back through `query()`.
- For reusable chainable query scopes on the model itself, a custom Eloquent query builder
  is a lighter alternative — see the core `MODEL-002-query-builders` pattern.

## Related

- `<PLUGIN_ROOT>/patterns-built/laravel/providers/PROVIDER-001-structure.md` — where the
  interface→implementation binding is registered.
- `<PLUGIN_ROOT>/patterns-built/laravel/services/SERVICE-002-domain-services.md` — services
  consume repositories via the interface.
