# CODE-002-oop-principles

## Pattern

The object-oriented defaults that keep a Laravel app testable and changeable as it grows. These
are the *why* behind the artifact patterns (Actions, Services, DTOs, contracts) — apply them in
**domain code** (Actions, Services, domain models). At the framework edges (controllers, commands,
providers) the conveniences below relax; that's fine.

Five defaults, each concrete.

## 1. Inject dependencies; don't reach for facades/statics in domain code

A class should receive what it needs through its constructor, so a test can pass substitutes and a
reader can see its collaborators at a glance.

```php
// ❌ Domain code reaching into global state — hidden dependencies, hard to test in isolation
final class CreateInvoiceAction
{
    public function execute(Order $order): Invoice
    {
        $rate = Cache::get('tax_rate');           // hidden dependency
        $invoice = Invoice::create([...]);
        Mail::to($order->user)->send(new InvoiceCreated($invoice));   // hidden dependency
        return $invoice;
    }
}

// ✅ Collaborators are explicit and swappable
final class CreateInvoiceAction
{
    public function __construct(
        private TaxRates $taxRates,
        private Mailer $mailer,
    ) {
    }

    public function execute(Order $order): Invoice { /* uses $this->taxRates, $this->mailer */ }
}
```

Facades and helpers (`Cache::`, `auth()`, `request()`) are fine in **controllers, commands, and
providers** — the framework edge. Keep them out of Actions/Services so the domain stays unit-testable.

## 2. Depend on abstractions at boundaries

Where a class talks to a third party, the clock, randomness, or another module, depend on a
**contract**, not the concrete — so the boundary can be faked in tests and swapped later. Inside a
module, depending on concretes is correct. Full guidance + the "don't over-abstract" line:
[CODE-003](./CODE-003-contracts.md).

## 3. Keep classes small and single-purpose

One class, one reason to change. A class accreting unrelated methods (`OrderService` that creates,
emails, and reports) should split into focused pieces — see [SERVICE-003](../services/SERVICE-003-when-to-use.md)
and [SERVICE-002](../services/SERVICE-002-domain-services.md). Small classes are easier to name,
test, and hold in your head.

## 4. Prefer immutability — `readonly`, value objects, immutable DTOs

State that can't change can't be corrupted or leak between requests. Make data carriers `readonly`;
model domain values as small value objects instead of bare primitives.

```php
// ✅ Immutable value object — validates its invariant once, can't be mutated into an invalid state
final readonly class Money
{
    public function __construct(public int $cents, public string $currency)
    {
        if ($cents < 0) {
            throw new \InvalidArgumentException('Money cannot be negative.');
        }
    }

    public function add(Money $other): self
    {
        return new self($this->cents + $other->cents, $this->currency);
    }
}
```

```php
// ✅ readonly DTO — a transport that can't be tampered with after construction
final readonly class CreateOrderData
{
    public function __construct(
        public string $reference,
        public int $subtotalCents,
        public float $taxRate,
    ) {
    }
}
```

Immutability also matters for long-lived workers (Octane): shared instances holding mutable state
leak across requests — see [PROVIDER-001](../providers/PROVIDER-001-structure.md).

## 5. Encapsulate — protect invariants, don't expose internals

An object should guard its own validity rather than trust every caller to set fields correctly.
Push the rule into the object (a constructor guard, a named method) instead of scattering the same
check across call sites.

```php
// ❌ Anemic — every caller must remember the rule, and some won't
$subscription->status = 'active';
$subscription->activated_at = now();

// ✅ The object owns the transition + its invariant
$subscription->activate($this->clock->now());
```

```php
final class Subscription extends Model
{
    public function activate(\DateTimeInterface $at): void
    {
        if ($this->status === 'cancelled') {
            throw new \DomainException('Cannot activate a cancelled subscription.');
        }
        $this->forceFill(['status' => 'active', 'activated_at' => $at])->save();
    }
}
```

## Composition over inheritance

Reach for collaboration between small objects (and traits for shared mechanics) before deep class
hierarchies. Inherit to satisfy a framework base (`Model`, `ServiceProvider`); compose for your own
behavior. A three-level domain inheritance chain is usually a sign a collaborator wants extracting.

## Key Points

- **Inject** collaborators in domain code (Actions/Services); facades/helpers stay at the framework
  edge (controllers, commands, providers)
- **Depend on abstractions at boundaries** only — contracts where swap/test payoff exists, concretes
  internally ([CODE-003](./CODE-003-contracts.md))
- **One class, one reason to change** — split accreting classes ([SERVICE-003](../services/SERVICE-003-when-to-use.md))
- **Prefer immutability** — `readonly` DTOs/value objects; model domain values as objects, not bare
  primitives; immutable state is Octane-safe
- **Encapsulate invariants** — the object owns its valid transitions; avoid anemic field-setting at
  call sites
- **Compose over inherit** — small collaborating objects + traits over deep hierarchies; inherit only
  for framework base classes
