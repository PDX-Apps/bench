# SERVICE-004-manager

## Pattern

When a capability has **several interchangeable implementations** chosen at runtime — payment
gateways, notification channels, export formats, storage backends — use Laravel's driver-based
**Manager**. The Manager owns *driver selection* (which implementation) and *driver creation*
(how to build it); each driver implements a shared **contract** so callers depend on the
capability, not the concrete.

This is the same machinery Laravel uses internally for `Cache`, `Mail`, `Filesystem`, and
`Notification` — a `Manager` subclass with one `create{Driver}Driver()` method per backend and a
config-driven default.

## When to reach for a Manager

| Reach for a Manager when… | Use something simpler when… |
|---------------------------|------------------------------|
| 2+ interchangeable implementations of one capability | A single implementation (just bind the contract — see [CODE-003](../code/CODE-003-contracts.md)) |
| The choice is config- or runtime-driven (`config('billing.gateway')`) | The choice is a fixed `match` on a value passed in (a small factory is enough) |
| Drivers are resolved lazily and reused | You build the object once at a call site |
| You want callers to stay unaware of which driver is active | Callers legitimately need a specific implementation |

Two interchangeable drivers is the threshold. One implementation does **not** justify a Manager —
that's a single contract binding. Don't build the indirection before the second driver exists.

## Structure

Each driver implements the shared contract:

```php
<?php

declare(strict_types=1);

namespace App\Contracts;

use App\Support\ChargeResult;

interface PaymentGateway
{
    public function charge(string $customerId, int $amountCents): ChargeResult;

    public function refund(string $chargeId): ChargeResult;
}
```

The Manager extends `Illuminate\Support\Manager`, names the default driver, and exposes one
`create{Studly}Driver()` per backend:

```php
<?php

declare(strict_types=1);

namespace App\Billing;

use App\Contracts\PaymentGateway;
use Illuminate\Support\Manager;

class PaymentGatewayManager extends Manager
{
    /**
     * The driver used when no name is given — driven by config, not hard-coded.
     */
    public function getDefaultDriver(): string
    {
        return $this->config->get('billing.gateway', 'stripe');
    }

    protected function createStripeDriver(): PaymentGateway
    {
        return new StripeGateway($this->config->get('billing.stripe.key'));
    }

    protected function createPaddleDriver(): PaymentGateway
    {
        return new PaddleGateway($this->config->get('billing.paddle.key'));
    }
}
```

`Manager` resolves drivers lazily through `driver()` (its `__call` forwards unknown methods to the
default driver) and **caches** each one, so a driver is constructed at most once per Manager
instance.

## Binding + usage

Bind the Manager as a singleton. Optionally alias the contract to the default driver so callers can
type-hint the capability directly (see [PROVIDER-001](../providers/PROVIDER-001-structure.md)):

```php
public function register(): void
{
    $this->app->singleton(PaymentGatewayManager::class);

    // Callers that don't care which gateway type-hint the contract:
    $this->app->bind(
        PaymentGateway::class,
        fn ($app) => $app->make(PaymentGatewayManager::class)->driver(),
    );
}
```

```php
// Default gateway — caller stays unaware of which one:
class CapturePaymentAction
{
    public function __construct(private PaymentGateway $gateway)
    {
    }

    public function execute(string $customerId, int $amountCents): ChargeResult
    {
        return $this->gateway->charge($customerId, $amountCents);
    }
}

// A specific gateway when the caller genuinely needs one:
$result = app(PaymentGatewayManager::class)->driver('paddle')->charge($customerId, $amountCents);
```

## Custom drivers from outside the Manager

`extend()` registers a driver the Manager doesn't know about (a package or per-project gateway)
without subclassing it:

```php
app(PaymentGatewayManager::class)->extend('offline', fn ($app) => new OfflineGateway());
```

## Anti-patterns

### ❌ A Manager for one implementation

```php
// Bad — there's only ever a Stripe gateway. This is indirection with no payoff.
class PaymentGatewayManager extends Manager
{
    public function getDefaultDriver(): string { return 'stripe'; }
    protected function createStripeDriver(): PaymentGateway { return new StripeGateway(...); }
}

// Better — one implementation is a single contract binding.
$this->app->singleton(PaymentGateway::class, StripeGateway::class);
```

### ❌ A `match` rebuilt at every call site

```php
// Bad — selection logic duplicated wherever a gateway is needed.
$gateway = match (config('billing.gateway')) {
    'stripe' => new StripeGateway(...),
    'paddle' => new PaddleGateway(...),
};

// Better — the Manager centralizes selection + lazy caching in one place.
$gateway = app(PaymentGatewayManager::class)->driver();
```

### ❌ Drivers that don't share a contract

If `StripeGateway` and `PaddleGateway` expose different method names, callers must branch on the
driver — defeating the point. Every driver implements the **same** contract; the Manager only
chooses which.

## Key Points

- Use for **2+ interchangeable implementations** of one capability, selected by config/runtime
- Extend `Illuminate\Support\Manager`; implement `getDefaultDriver()` (read from config) + one
  `create{Studly}Driver()` per backend returning the **contract** type
- Every driver implements a shared contract (see [CODE-003](../code/CODE-003-contracts.md)); callers depend on the contract
- Bind the Manager as a `singleton`; optionally alias the contract to `->driver()` for callers
  that don't care which backend is active
- `driver('name')` selects explicitly; the unqualified Manager forwards to the default driver;
  drivers are built lazily and cached
- `extend('name', fn)` adds a driver without subclassing — for packages or per-project backends
- **One implementation is not a Manager** — that's a single contract binding. Don't pre-build the
  indirection.
