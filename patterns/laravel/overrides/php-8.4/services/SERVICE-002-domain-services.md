---
overrides: base/services/SERVICE-002-domain-services.md
target: php-8.4
reason: PHP 8.4 doesn't have the pipe operator |> — chain via nested function calls or fluent method chains instead.
base-hash: 940098
---

> ⚠️ **PHP 8.4 — no pipe operator.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# SERVICE-002-domain-services

## Pattern

Focused domain utilities with specific purposes. Not generic "do everything" services.

## Why

Services should have descriptive names that clearly indicate their specific purpose. Avoid generic names like `UserService`, `DataProcessor`, or `Helper`.

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Support\Collection;

class PricingCalculator
{
    /**
     * Break a subtotal into tax and total (all amounts in cents).
     */
    public function breakdown(int $subtotalCents, float $taxRate): array
    {
        $tax = (int) round($subtotalCents * $taxRate);

        return [
            'subtotal' => $subtotalCents,
            'tax' => $tax,
            'total' => $subtotalCents + $tax,
        ];
    }

    /**
     * Project recurring revenue over a number of billing periods, with optional growth.
     */
    public function projectRecurringRevenue(int $amountCents, int $periods, float $growthRate = 0.0): int
    {
        if ($growthRate === 0.0) {
            return $amountCents * $periods;
        }

        $total = 0;
        $current = $amountCents;

        for ($i = 0; $i < $periods; $i++) {
            $total += $current;
            $current = (int) round($current * (1 + $growthRate));
        }

        return $total;
    }

    /**
     * Compare actual spend per category against planned limits.
     */
    public function calculateVariance(Collection $lineItems, array $limits): array
    {
        $actualByCategory = $lineItems->groupBy('category')
            ->map(fn ($items) => $items->sum('amount_cents'))
            ->toArray();

        $variances = [];

        foreach ($limits as $category => $limit) {
            $actual = $actualByCategory[$category] ?? 0;
            $variances[$category] = [
                'limit' => $limit,
                'actual' => $actual,
                'difference' => $limit - $actual,
                'percentage' => $limit > 0 ? round(($actual / $limit) * 100, 2) : 0,
            ];
        }

        return $variances;
    }
}
```

## Transformation Pipelines (no pipe operator on 8.4)

Domain services often run a value through a sequence of transformations: parse → normalize → validate → format. PHP 8.5's pipe operator (`|>`) chains these left-to-right, but it isn't available on 8.4. Chain via nested function calls, or — when each step stays on the same type — a fluent method chain.

### Nested calls

```php
class ImportRowNormalizer
{
    public function normalizeRow(string $rawRow): NormalizedRow
    {
        return $this->buildNormalized(
            $this->parseAmount(
                $this->stripCurrencySymbols(
                    trim(
                        strtolower($rawRow)
                    )
                )
            )
        );
    }
}
```

Reading order is inside-out. Each new step adds another wrapping layer.

### Intermediate variables (clearer for longer chains)

When the nesting gets deep, name each step with an intermediate variable so the flow reads top-to-bottom:

```php
class ImportRowNormalizer
{
    public function normalizeRow(string $rawRow): NormalizedRow
    {
        $lowered = strtolower($rawRow);
        $trimmed = trim($lowered);
        $stripped = $this->stripCurrencySymbols($trimmed);
        $amount = $this->parseAmount($stripped);

        return $this->buildNormalized($amount);
    }
}
```

### Fluent chains for same-type pipelines

For Laravel collections specifically, the existing fluent chain reads cleanly because each step returns the same type:

```php
public function summarize(Collection $lineItems): array
{
    return $lineItems
        ->where('amount_cents', '>', 0)
        ->groupBy('category')
        ->map(fn ($items) => $items->sum('amount_cents'))
        ->toArray();
}
```

Fluent chains shine for same-type pipelines (Eloquent / Collection). For **mixed-type pipelines** where each step swaps the underlying type, prefer named intermediate variables over deep nesting.

## Good vs. Bad Service Names

### ✅ Good - Focused and Descriptive

```php
// Clear purpose: parses strings
class StringParser
{
    public function extractEmails(string $text): array
    public function sanitize(string $text): string
}

// Clear purpose: sends notifications
class NotificationDispatcher
{
    public function send(User $user, Notification $notification): void
    public function sendBulk(Collection $users, Notification $notification): void
}

// Clear purpose: Stripe API client
class StripeClient
{
    public function createCustomer(array $data): Customer
    public function charge(string $customerId, int $amount): Charge
}
```

### ❌ Bad - Generic and Vague

```php
// What does this do? Everything?
class OrderService
{
    public function create()
    public function sendEmail()
    public function generateReport()
    public function processPayment()
}

// Too generic - processes what?
class DataProcessor
{
    public function process()
}

// What kind of helper? For what?
class Helper
{
    public function doStuff()
}
```

## DDD Principles

Services must stay within their domain boundaries:

```php
// ✅ Good - PricingCalculator only handles calculations
class PricingCalculator
{
    public function breakdown(int $subtotalCents, float $taxRate): array
    public function projectRecurringRevenue(int $amountCents, int $periods): int
}

// ❌ Bad - PricingCalculator sending emails?
class PricingCalculator
{
    public function breakdown(int $subtotalCents, float $taxRate): array
    public function emailInvoice(User $user): void  // Wrong domain!
}

// ✅ Good - Separate concerns
class PricingCalculator
{
    public function breakdown(int $subtotalCents, float $taxRate): array
}

class InvoiceDispatcher
{
    public function emailInvoice(User $user, array $invoice): void
}
```

## Usage

```php
// In an Action — the calculator computes, the Action persists
class CreateOrderAction
{
    public function __construct(
        private PricingCalculator $pricing,
    ) {
    }

    public function execute(User $user, CreateOrderData $data): Order
    {
        $breakdown = $this->pricing->breakdown($data->subtotalCents, $data->taxRate);

        $order = new Order();
        $order->user_id = $user->id;           // explicit — never mass-assigned
        $order->subtotal_cents = $breakdown['subtotal'];
        $order->tax_cents = $breakdown['tax'];
        $order->total_cents = $breakdown['total'];
        $order->save();

        event(new OrderCreated($order->id));

        return $order;
    }
}
```

## Key Points

- Lives in `app/Services/`
- Name pattern: Descriptive of a specific purpose (Engine, Parser, Dispatcher, Client, Builder)
- Multiple focused methods are allowed (as long as all are related to the service's purpose)
- Stateless when possible
- Stay within domain boundaries — never cross domains (a `PricingCalculator` doesn't build queries)
- Avoid generic names (`OrderService`, `DataProcessor`, `Helper`)
- **PHP 8.4: no pipe operator — chain via nested calls, named intermediate variables, or fluent chains**

## When to Use Services

**Use Services for:**
- Domain utilities (calculations, parsing, formatting, transformation)
- External API facades (StripeClient, S3Client)
- Specialized tools (PricingCalculator, CurrencyConverter, TokenGenerator)
- Focused responsibilities that don't fit as Actions

**Don't Use Services for:**
- Generic "do everything" classes
- Business operations (use Actions instead)
- Simple one-method utilities (use static methods or helpers)
