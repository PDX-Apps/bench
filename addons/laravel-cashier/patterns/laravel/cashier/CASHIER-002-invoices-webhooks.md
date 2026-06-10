# CASHIER-002 — Invoices, Single Charges & Webhooks (Laravel Cashier / Stripe)

Invoicing, one-off charges, and securely reacting to Stripe webhooks.

## Single charges

`charge()` takes the amount in the **smallest currency unit** (cents) and a
payment-method id collected via Stripe.js.

```php
$payment = $customer->charge(1000, $paymentMethodId); // $10.00
```

Charge and attach an invoice line item in one step:

```php
$customer->invoiceFor('One-off setup fee', 5000); // $50.00
```

Refund a payment by its payment-intent id:

```php
$customer->refund($payment->id);
```

## Invoices

```php
$invoices = $customer->invoices();          // paid invoices
$invoices = $customer->invoicesIncludingPending();
$invoice  = $customer->findInvoice($invoiceId);

$invoice->total();        // formatted, e.g. "$10.00"
$invoice->date();         // Carbon instance
```

Let a customer download a PDF — return the streamed response directly:

```php
use Illuminate\Http\Request;

public function download(Request $request, string $invoiceId)
{
    return $request->user()->downloadInvoice($invoiceId, [
        'vendor'  => 'Acme, Inc.',
        'product' => 'Pro Subscription',
    ]);
}
```

Always scope invoice lookups to the authenticated owner so one customer can
never fetch another's invoice id.

## Webhooks

Cashier registers a webhook route at `/stripe/webhook` (the `cashier.path`
config prefix) and handles subscription/customer lifecycle events for you:
cancellations, renewals, payment failures keep your local DB in sync.

### 1. Point Stripe at the route

In the Stripe dashboard (or CLI) send events to
`https://your-app.test/stripe/webhook`. Subscribe to at least:
`customer.subscription.created/updated/deleted`,
`invoice.payment_succeeded`, `invoice.payment_failed`,
`customer.updated`, `customer.deleted`.

### 2. Verify signatures (required)

Set `STRIPE_WEBHOOK_SECRET` and keep Cashier's signature-verification
middleware enabled (it is, by default). It rejects any request whose
`Stripe-Signature` header doesn't match — this is what stops forged webhook
calls. Never disable it.

The webhook route must be **exempt from CSRF** (it's an external POST). Cashier's
own route already is; if you proxy it, keep the exemption.

### 3. React to extra events

For events Cashier doesn't handle internally, listen for its events instead of
subclassing the controller:

```php
use Illuminate\Support\Facades\Event;
use Laravel\Cashier\Events\WebhookReceived;

// e.g. in a service provider's boot()
Event::listen(WebhookReceived::class, function (WebhookReceived $event) {
    if ($event->payload['type'] === 'invoice.payment_succeeded') {
        // provision access for the renewal, send a receipt, etc.
    }
});
```

`WebhookReceived` fires for every event before Cashier processes it;
`WebhookHandled` fires after. Keep listener work fast or push it onto a queue —
Stripe retries on slow/failed responses.

## Rules

- Amounts are integers in the smallest currency unit (cents).
- Keep signature verification on; `STRIPE_WEBHOOK_SECRET` is mandatory.
- The webhook route is CSRF-exempt; never wrap it in the web CSRF middleware.
- Scope every invoice lookup to the authenticated owner.
- Treat webhooks as the source of truth for renewals & failures; do heavy work on a queue.
