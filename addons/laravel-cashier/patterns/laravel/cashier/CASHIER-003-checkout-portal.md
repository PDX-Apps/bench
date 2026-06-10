# CASHIER-003 — Stripe Checkout & Billing Portal (Laravel Cashier / Stripe)

Two **Stripe-hosted** flows that mean you don't build (or PCI-scope) any card UI yourself: **Checkout** (a hosted payment page) and the **Billing Portal** (a hosted self-service page for plans, payment methods, and invoices). 

## Stripe Checkout (hosted payment page)

Redirect the customer to a Stripe-hosted page; they pay there and return. No payment-method collection in your app.

**One-off product checkout** — first arg is a price id (or `['price_id' => quantity]`), second is session options:

```php
use Illuminate\Http\Request;

public function checkout(Request $request)
{
    return $request->user()->checkout(['price_tshirt' => 1], [
        'success_url' => route('checkout.success').'?session_id={CHECKOUT_SESSION_ID}',
        'cancel_url'  => route('checkout.cancel'),
    ]);
}
```

**Ad-hoc single charge** (no predefined price) — amount in the smallest currency unit:

```php
$request->user()->checkoutCharge(1200, 'T-Shirt', 1, [
    'success_url' => route('home'),
    'cancel_url'  => route('home'),
]);
```

**Subscription checkout** — start from `newSubscription()` and call `->checkout()` instead of `->create()` (Checkout collects the payment method):

```php
$request->user()
    ->newSubscription('default', 'price_monthly')
    ->trialDays(5)
    ->allowPromotionCodes()
    ->checkout([
        'success_url' => route('billing'),
        'cancel_url'  => route('billing'),
    ]);
```

- Defaults: if you omit `success_url`/`cancel_url`, Cashier falls back to `route('home')` with a `?checkout=success|cancelled` flag.
- **Embedded / custom UI mode:** pass `'ui_mode' => 'embedded'` and a `return_url` (instead of success/cancel URLs) to render Checkout inside your page.
- **Fulfil on return, not on redirect:** the success URL means "they reached the page", not "payment cleared". Confirm via the session (`{CHECKOUT_SESSION_ID}` → `Cashier::stripe()->checkout->sessions->retrieve($id)`) and, authoritatively, via the **webhook** — webhooks are the source of truth.

## Billing Portal (hosted self-service)

Let an existing customer manage their subscription, payment methods, and invoices on Stripe's hosted portal:

```php
// Redirect straight to the portal; returnUrl is where Stripe sends them back.
return $request->user()->redirectToBillingPortal(route('dashboard'));

// Or just get the URL (e.g. to render a link):
$url = $request->user()->billingPortalUrl(route('dashboard'));
```

The customer must already be a Stripe customer (has subscribed or been charged, so a `stripe_id` exists) — otherwise create one first (`$user->createAsStripeCustomer()`).

## When to use which

- **Checkout** → you want Stripe to host payment + own card-field PCI scope; fastest path to taking money. Use the Payment Element only when you need a fully custom in-app checkout.
- **Billing Portal** → don't hand-build "change plan / update card / download invoices" screens; the portal does it, configured in the Stripe dashboard.

## Rules

- Amounts are integers in the smallest currency unit (cents).
- **Confirm fulfilment via webhook**, not the Checkout `success_url` — the redirect can happen without a cleared payment.
- Keep `success_url`/`cancel_url`/`return_url` as your own routes; pass `{CHECKOUT_SESSION_ID}` through if you need to look the session up.
- The billing portal needs an existing Stripe customer; create one before redirecting if none exists.
