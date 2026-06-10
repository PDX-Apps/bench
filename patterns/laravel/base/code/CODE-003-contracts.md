# CODE-003-contracts

## Pattern

A **contract** is an interface that names a capability — `PaymentGateway`, `Clock`,
`HtmlSanitizer` — so callers depend on *what* a thing does, not *which* class does it. Extract a
contract at the **boundaries** of your application; depend on the concrete everywhere else.

This is the practical form of "depend on abstractions".
The goal is swap-ability where swap-ability has a payoff — not an interface for every class.

## Extract a contract when the class is a boundary

Default to a contract when the class sits on one of these seams:

| Boundary | Why a contract earns its place | Example |
|----------|-------------------------------|---------|
| **External-service facade** | Isolates a third party so it can be faked in tests and swapped if you change vendors | `PaymentGateway`, `EmailProvider`, `SearchIndex` |
| **Interchangeable strategies** | Two+ implementations chosen at runtime — pairs with a Manager | `PaymentGateway` (stripe/paddle), `ExportFormat` (csv/xlsx) |
| **A module's public surface** | The one entry point other modules call; the internals stay private behind it | `Billing`, `Inventory` facade contracts |
| **Non-deterministic dependency** | Lets a test inject a fixed value instead of real time/randomness/IO | `Clock`, `RandomTokenGenerator`, `Filesystem` |

## Do NOT extract a contract when

- The class has **one implementation and no swap need** — a focused `PricingCalculator` that only
  ever calculates is just a class. Inject it directly.
- It's an **internal collaborator** wholly owned by one module — extracting an interface there adds
  a file and a layer of indirection for no caller benefit.
- You're abstracting **"just in case."** A second implementation that doesn't exist yet is not a
  reason. Extract the contract when the second implementation (or the test-double need) actually
  arrives — the refactor is cheap.

A single-implementation interface you created speculatively is a cost (two files, an indirection)
with no benefit. Boundaries justify the cost; internals don't.

## Where contracts live

```
app/
├── Contracts/
│   ├── PaymentGateway.php
│   └── Clock.php
├── Billing/
│   └── StripeGateway.php      # implements Contracts\PaymentGateway
└── Support/
    └── SystemClock.php        # implements Contracts\Clock
```

```php
<?php

declare(strict_types=1);

namespace App\Contracts;

interface Clock
{
    public function now(): \DateTimeImmutable;
}
```

```php
<?php

declare(strict_types=1);

namespace App\Support;

use App\Contracts\Clock;

final class SystemClock implements Clock
{
    public function now(): \DateTimeImmutable
    {
        return new \DateTimeImmutable();
    }
}
```

## Bind, then type-hint the contract

Bind interface → implementation in a service provider; callers type-hint the contract and the
container injects the bound concrete:

```php
// Provider
$this->app->singleton(Clock::class, SystemClock::class);
```

```php
// Caller depends on the capability, not the class
final class ExpireSubscriptionsAction
{
    public function __construct(private Clock $clock)
    {
    }

    public function execute(): void
    {
        $cutoff = $this->clock->now();
        Subscription::query()->where('ends_at', '<', $cutoff)->update(['status' => 'expired']);
    }
}
```

## The payoff: test without the real boundary

A contract lets a test inject a fake — no real vendor call, no real clock — and assert behavior in
isolation:

```php
final class FrozenClock implements Clock
{
    public function __construct(private \DateTimeImmutable $at)
    {
    }

    public function now(): \DateTimeImmutable
    {
        return $this->at;
    }
}

// In the test: deterministic time, no framework boot needed for the unit under test.
$action = new ExpireSubscriptionsAction(new FrozenClock(new \DateTimeImmutable('2026-01-01')));
```

## Anti-patterns

### ❌ Interface per class ("just in case")

```php
// Bad — OrderRepositoryInterface, PricingCalculatorInterface, EmailFormatterInterface…
// every class shadowed by a one-impl interface. Indirection tax, no swap, no test benefit.
```

### ❌ A contract that leaks its implementation

```php
// Bad — the "contract" exposes Stripe types, so callers still depend on Stripe.
interface PaymentGateway
{
    public function charge(\Stripe\Customer $c, int $amount): \Stripe\Charge;
}

// Better — the contract speaks your domain; implementations translate at their edge.
interface PaymentGateway
{
    public function charge(string $customerId, int $amountCents): ChargeResult;
}
```

## Key Points

- A contract names a capability so callers depend on the abstraction, not the concrete
- Extract at **boundaries**: external-service facades, interchangeable strategies, a module's
  public surface, non-deterministic dependencies (time/random/IO)
- **Do not** extract for single-implementation internals or speculative "might need it later" cases
  — add the interface when the second impl or the test-double need actually arrives
- Contracts live in `app/Contracts/`; the contract speaks your **domain**, never leaks vendor types
- Bind interface → implementation in a provider; callers type-hint the contract
- Interchangeable drivers behind one contract → reach for a Manager
- The concrete payoff is testability: inject a fake implementation instead of the real boundary
