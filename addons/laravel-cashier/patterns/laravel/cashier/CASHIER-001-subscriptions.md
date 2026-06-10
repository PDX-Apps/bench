# CASHIER-001 — Subscriptions (Laravel Cashier / Stripe)

How to make a model billable and run the core subscription lifecycle:
create, trial, swap, status checks, cancel/resume.

> Cashier speaks Stripe **Prices** (`price_xxx`), not legacy "plans". Method
> names use `Price` (`subscribedToPrice`, `onPrice`), and `newSubscription()`
> takes a price id. Keep price ids in config, never hardcoded in flows.

## Install

```bash
composer require laravel/cashier
php artisan vendor:publish --tag="cashier-migrations"
php artisan migrate
```

`.env`:

```dotenv
STRIPE_KEY=pk_test_xxx
STRIPE_SECRET=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

## Make the model Billable

Add the `Billable` trait to whatever model owns the subscription — the
`Customer`, `User`, `Team`, etc. It adds the customer columns + subscription
relationships (published by the Cashier migrations).

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Cashier\Billable;

class Customer extends Authenticatable
{
    use Billable;
}
```

## Create a subscription

The first argument is an internal subscription **type** (`default`,
`swimming`, …) — your label, not Stripe's. The second is the Stripe price id.
`create()` takes a payment-method id (`pm_xxx`) collected client-side via
Stripe.js / Payment Element.

```php
$customer->newSubscription('default', 'price_basic_monthly')
    ->create($paymentMethodId);
```

### With a trial

```php
$customer->newSubscription('default', 'price_basic_monthly')
    ->trialDays(14)
    ->create($paymentMethodId);

// Extend an existing trial
$customer->subscription('default')->extendTrial(now()->addDays(7));
```

Use config for the price id so test/live ids don't leak into code:

```php
$customer->newSubscription('default', config('billing.prices.basic'))
    ->trialDays(config('billing.trial_days'))
    ->create($paymentMethodId);
```

## Swap plans

```php
$customer->subscription('default')->swap('price_pro_monthly');
$customer->subscription('default')->noProrate()->swap('price_pro_monthly');
$customer->subscription('default')->swapAndInvoice('price_pro_monthly'); // invoice now
$customer->subscription('default')->skipTrial()->swap('price_pro_monthly');
```

## Cancel & resume

```php
$customer->subscription('default')->cancel();     // ends at period end (grace period)
$customer->subscription('default')->cancelNow();  // ends immediately
$customer->subscription('default')->resume();     // only valid during the grace period
```

## Check status

Drive feature gates and UI off these — never off raw Stripe state.

```php
$customer->subscribed('default');                  // active (incl. trial / grace period)
$customer->subscribedToPrice('price_basic_monthly', 'default');
$customer->onTrial('default');
$customer->onGracePeriod('default');               // canceled but still within paid period
$customer->subscription('default')->canceled();
$customer->subscription('default')->ended();
$customer->subscription('default')->recurring();   // active, not on trial / grace
$customer->subscription('default')->pastDue();
```

Gate access via middleware or a policy:

```php
if (! $customer->subscribed('default')) {
    abort(402, 'An active subscription is required.');
}
```

## Incomplete payments (SCA / 3DS)

When a charge needs extra confirmation the subscription is created
`incomplete`. Surface the confirmation link:

```php
if ($customer->hasIncompletePayment('default')) {
    // route the user to: route('cashier.payment', $customer->subscription('default')->latestPayment()->id)
}
```

## Rules

- Subscription **type** is your internal label; the price id is Stripe's.
- Keep price ids and trial lengths in `config/billing.php`, not inline.
- Gate features off `subscribed()` / `subscribedToPrice()`, not Stripe API reads.
- Collect payment methods with Stripe.js (`pm_xxx`); never accept raw card data.
- Webhooks (not the create call) are the source of truth for renewals.
