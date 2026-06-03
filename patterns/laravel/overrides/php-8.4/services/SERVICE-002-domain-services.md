---
overrides: base/services/SERVICE-002-domain-services.md
target: php-8.4
reason: PHP 8.4 doesn't have the pipe operator |> — chain via nested function calls or fluent method chains instead.
base-hash: 08a273
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

namespace Modules\Budget\Services;

use Carbon\Carbon;
use Illuminate\Support\Collection;

class BudgetCalculator
{
    /**
     * Calculate monthly budget allocation from income.
     */
    public function calculateAllocation(int $monthlyIncome): array
    {
        return [
            'needs' => (int) ($monthlyIncome * 0.50),      // 50% needs
            'wants' => (int) ($monthlyIncome * 0.30),      // 30% wants
            'savings' => (int) ($monthlyIncome * 0.20),    // 20% savings
        ];
    }

    /**
     * Calculate projected savings based on monthly contribution.
     */
    public function projectSavings(int $monthlyAmount, int $months, float $annualRate = 0.0): int
    {
        if ($annualRate === 0.0) {
            return $monthlyAmount * $months;
        }

        $monthlyRate = $annualRate / 12;
        $futureValue = 0;

        for ($i = 0; $i < $months; $i++) {
            $futureValue = ($futureValue + $monthlyAmount) * (1 + $monthlyRate);
        }

        return (int) $futureValue;
    }

    /**
     * Calculate spending variance from budget categories.
     */
    public function calculateVariance(Collection $transactions, array $budgetLimits): array
    {
        $actualByCategory = $transactions->groupBy('category')
            ->map(fn($items) => $items->sum('amount'))
            ->toArray();

        $variances = [];

        foreach ($budgetLimits as $category => $limit) {
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
class UserService
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
// ✅ Good - BudgetCalculator only handles calculations
class BudgetCalculator
{
    public function calculateAllocation(int $income): array
    public function projectSavings(int $amount, int $months): int
}

// ❌ Bad - BudgetCalculator sending emails?
class BudgetCalculator
{
    public function calculateAllocation(int $income): array
    public function emailBudgetReport(User $user): void  // Wrong domain!
}

// ✅ Good - Separate concerns
class BudgetCalculator
{
    public function calculateAllocation(int $income): array
}

class BudgetReportDispatcher
{
    public function emailReport(User $user, array $budget): void
}
```

## Usage

```php
// In Action
class CreateBudgetAction
{
    public function __construct(
        private BudgetCalculator $calculator,
    ) {
    }

    public function execute(BudgetData $data): Budget
    {
        $allocation = $this->calculator->calculateAllocation($data->monthlyIncome);

        $budget = Budget::create([
            'user_id' => $data->userId,
            'monthly_income' => $data->monthlyIncome,
            'needs_allocation' => $allocation['needs'],
            'wants_allocation' => $allocation['wants'],
            'savings_allocation' => $allocation['savings'],
        ]);

        event(new BudgetCreated($budget));

        return $budget;
    }
}
```

## Key Points

- Lives in `Modules/{Module}/Services/`
- Name pattern: Descriptive of a specific purpose (Engine, Parser, Dispatcher, Client, Builder)
- Multiple focused methods are allowed (as long as all are related to the service's purpose)
- Stateless when possible
- Stay within domain boundaries
- Never cross domains (PdfEngine doesn't build queries)
- Avoid generic names (UserService, DataProcessor, Helper)

## When to Use Services

**Use Services for:**
- Domain utilities (calculations, parsing, formatting, transformation)
- External API facades (StripeClient, S3Client)
- Specialized tools (BudgetCalculator, CurrencyConverter, TokenGenerator)
- Focused responsibilities that don't fit as Actions

**Don't Use Services for:**
- Generic "do everything" classes
- Business operations (use Actions instead)
- Simple one-method utilities (use static methods or helpers)
