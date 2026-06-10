# SERVICE-003-when-to-use

## Pattern

Decision guide for choosing between Actions, Services, or neither — plus when a capability has
several interchangeable implementations (→ a driver-based Manager).

## Decision Tree

```
Need to implement business logic?

├─ Complex business operation (create, update, process)?
│  ├─ Multi-step process?
│  │  └─ Use Action (CreateOrderAction)
│  ├─ Reused across controllers/jobs/commands?
│  │  └─ Use Action (ProcessPaymentAction)
│  └─ Needs isolated testing?
│     └─ Use Action (SendWelcomeEmailAction)
│
├─ Domain utility (parse, generate, transform)?
│  ├─ Specific tool/utility?
│  │  └─ Use Service (CurrencyConverter, StringParser)
│  ├─ External API integration?
│  │  └─ Use Service (StripeClient, S3Client)
│  └─ Focused responsibility?
│     └─ Use Service (NotificationDispatcher)
│
└─ Simple CRUD operation?
   └─ Use model methods directly
```

## Examples

### Use Action

**Complex multistep business operation:**
```php
// ✅ Use Action
class CreateOrderAction
{
    public function execute(User $user, CreateOrderData $data): Order
    {
        $order = new Order();
        $order->user_id = $user->id;
        $order->reference = $data->reference;
        $order->save();

        $this->addLineItems($order, $data->items);
        event(new OrderCreated($order->id));

        return $order;
    }
}
```

**Reused across different contexts:**
```php
// ✅ Use Action - called from controller, job, and command
class ProcessPaymentAction
{
    public function execute(PaymentData $data): Payment
    {
        // Complex payment processing logic
    }
}

// Controller
$action->execute($request->toDto());

// Job
$action->execute(PaymentData::fromInput($this->payload));

// Command
$action->execute(new PaymentData(...));
```

### Use Service

**Focused domain utility:**
```php
// ✅ Use Service - specific purpose (pricing calculations)
class PricingCalculator
{
    public function breakdown(int $subtotalCents, float $taxRate): array
    public function projectRecurringRevenue(int $amountCents, int $periods): int
    public function calculateVariance(Collection $lineItems, array $limits): array
}
```

**External API facade:**
```php
// ✅ Use Service - wraps external service
class StripeClient
{
    public function createCustomer(array $data): Customer
    public function charge(string $customerId, int $amount): Charge
    public function refund(string $chargeId): Refund
}
```

### Use Neither

**Simple CRUD operation (high-write, low-processing):**
```php
// ✅ Just use a model method - simple tracking, no business logic
public function store(Request $request): JsonResponse
{
    $click = Click::create([
        'url' => $request->input('url'),
        'user_id' => $request->user()?->id,
        'ip_address' => $request->ip(),
    ]);

    return response()->json(['data' => new ClickResource($click)], 201);
}

// ❌ Unnecessary Action for trivial operation
class TrackClickAction
{
    public function execute(array $data): Click
    {
        return Click::create($data); // Too simple for an Action
    }
}
```

## Common Patterns

### Action + Service Together

```php
class CreateOrderAction
{
    public function __construct(
        private PricingCalculator $pricing,  // Service
    ) {
    }

    public function execute(User $user, CreateOrderData $data): Order
    {
        $breakdown = $this->pricing->breakdown($data->subtotalCents, $data->taxRate);

        $order = new Order();
        $order->user_id = $user->id;
        $order->subtotal_cents = $breakdown['subtotal'];
        $order->tax_cents = $breakdown['tax'];
        $order->total_cents = $breakdown['total'];
        $order->save();

        return $order;
    }
}
```

### Actions Calling Actions

```php
class OnboardUserAction
{
    public function __construct(
        private CreateUserAction $createUser,
        private SendWelcomeEmailAction $sendWelcome,
        private AssignDefaultRoleAction $assignRole,
    ) {
    }

    public function execute(UserData $data): User
    {
        $user = $this->createUser->execute($data);
        $this->assignRole->execute($user, 'member');
        $this->sendWelcome->execute($user);

        return $user;
    }
}
```

### Interchangeable implementations → Manager

When the same capability has **2+ implementations chosen at runtime** (payment gateways,
notification channels, export formats), don't scatter a `match` across call sites — use a
driver-based **Manager** with each driver behind a shared
contract.

```php
// One capability, several backends, selected by config:
$gateway = app(PaymentGatewayManager::class)->driver();          // default from config
$gateway = app(PaymentGatewayManager::class)->driver('paddle');  // a specific one
```

One implementation is **not** a Manager — that's a single contract binding. Reach for the Manager
when the second driver actually exists.

## Anti-Patterns

### ❌ Generic Service Names

```php
// Bad - what does this do?
class UserService
{
    public function create()
    public function sendEmail()
    public function generateReport()
}

// Better - split into focused pieces
class CreateUserAction  // Business operation
class UserEmailDispatcher  // Focused service
class UserReportGenerator  // Focused service
```

### ❌ Services Crossing Domains

```php
// Bad - PricingCalculator persisting data?
class PricingCalculator
{
    public function breakdown(int $subtotalCents, float $taxRate): array
    public function saveOrderToDatabase(array $data): Order  // Wrong!
}

// Better - separate concerns
class PricingCalculator  // Only calculations
class CreateOrderAction  // Handles persistence
```

### ❌ Actions for Trivial Operations

```php
// Bad - too simple for an Action
class GetUserByIdAction
{
    public function execute(int $id): User
    {
        return User::findOrFail($id);
    }
}

// Better - just use the model
$user = User::findOrFail($id);
```

## Summary

**Actions (Business Operations):**
- Represent business operations (Create, Update, Process, Send)
- Complex, multi-step logic
- Reused across contexts
- Single `execute()` method

**Services (Domain Utilities):**
- Focused, specific purpose (Engine, Parser, Client, Dispatcher)
- Domain utilities and tools
- External API facades
- Multiple related methods are allowed

**Neither:**
- Simple CRUD operations
- Trivial one-liners
- Basic model methods

**Manager (Interchangeable Implementations):**
- One capability with 2+ runtime-selected backends (gateways, channels, formats)
- Each driver behind a shared contract; selection driven by config
- Reach for a driver-based Manager — not for a single implementation
