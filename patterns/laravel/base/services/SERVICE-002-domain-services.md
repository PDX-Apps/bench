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

## PHP 8.5: Pipe Operator (`|>`) for Transformation Pipelines

Domain services often run a value through a sequence of transformations: parse → normalize → validate → format. PHP 8.5's pipe operator chains these left-to-right instead of nesting them right-to-left.

### Before (nested calls)

```php
class TransactionImporter
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

### After (pipe operator)

```php
class TransactionImporter
{
    public function normalizeRow(string $rawRow): NormalizedRow
    {
        return $rawRow
            |> strtolower(...)
            |> trim(...)
            |> $this->stripCurrencySymbols(...)
            |> $this->parseAmount(...)
            |> $this->buildNormalized(...);
    }
}
```

Reading order is top-to-bottom in the natural flow direction. New steps are a single line addition.

### Pipe with Closures

When you need a step that isn't already a single-arg function, use a closure:

```php
public function summarize(Collection $transactions): array
{
    return $transactions
        |> fn(Collection $t) => $t->where('amount', '>', 0)
        |> fn(Collection $t) => $t->groupBy('category')
        |> fn(Collection $t) => $t->map(fn($items) => $items->sum('amount'))
        |> fn(Collection $t) => $t->toArray();
}
```

For Laravel collections specifically, the existing fluent chain (`->where()->groupBy()->map()`) is usually cleaner — pipe shines for **mixed-type pipelines** where each step swaps the underlying type.

### When to Use Pipe

| Use pipe when... | Don't use pipe when... |
|------------------|------------------------|
| Multi-step transformation across types (string → array → DTO → entity) | A single fluent chain on the same type works (Eloquent / Collection) |
| Each step is a single-input pure function | A step needs side effects or branching |
| Reading inside-out is harder than the steps deserve | The chain is only 2 calls (just nest) |

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
- **PHP 8.5+: prefer pipe operator (`|>`) for multi-type transformation pipelines**

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
