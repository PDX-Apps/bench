# bench-cashier

Laravel **Cashier (Stripe)** billing — subscriptions, plan swaps, trials, cancellation/grace periods, single charges, invoices, and secure webhook handling.

## What it ships

- **`/cashier`** skill + **`cashier`** agent — make a model `Billable` and wire the subscription lifecycle, charges, invoices, or webhooks.
- **`CASHIER-001-subscriptions`** — the `Billable` trait, creating subscriptions, trials, swapping prices, cancel/resume, status checks.
- **`CASHIER-002-invoices-webhooks`** — invoices, single charges, and handling Stripe webhooks securely (signature verification, event listeners).

> "Billing" is the domain here; "Billable" is Cashier's trait. The example entity is **Customer**.

## Install

```bash
bench addon add /path/to/bench/addons/bench-cashier
bench rebuild
```

Then `/cashier make Customer billable with a 14-day trial on the basic plan, plus webhook handling`.

## Requires (in the target project)

```bash
composer require laravel/stripe
php artisan vendor:publish --tag="cashier-migrations"
php artisan migrate
```

`.env`: `STRIPE_KEY`, `STRIPE_SECRET`, `STRIPE_WEBHOOK_SECRET`.
