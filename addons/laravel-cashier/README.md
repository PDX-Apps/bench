# laravel-cashier

Laravel **Cashier (Stripe)** billing — subscriptions, plan swaps, trials, cancellation/grace periods, single charges, **Stripe Checkout + the billing portal**, invoices, and secure webhook handling.

## What it ships

- **`/cashier`** skill + **`cashier`** agent — make a model `Billable` and wire the subscription lifecycle, charges, hosted Checkout / billing portal, invoices, or webhooks.
- **`CASHIER-001-subscriptions`** — the `Billable` trait, creating subscriptions, trials, swapping prices, cancel/resume, status checks.
- **`CASHIER-002-invoices-webhooks`** — invoices, single charges, and handling Stripe webhooks securely (signature verification, event listeners).
- **`CASHIER-003-checkout-portal`** — Stripe-hosted **Checkout** (product/subscription/ad-hoc) and the self-service **billing portal** (no card UI to build).

> "Billing" is the domain here; "Billable" is Cashier's trait. The example entity is **Customer**.

## Install

```bash
bench addon add laravel-cashier
bench rebuild
```

Then `/cashier make Customer billable with a 14-day trial on the basic plan, plus webhook handling`.

## Requires (in the target project)

```bash
composer require laravel/cashier
php artisan vendor:publish --tag="cashier-migrations"
php artisan migrate
```

`.env`: `STRIPE_KEY`, `STRIPE_SECRET`, `STRIPE_WEBHOOK_SECRET`.
