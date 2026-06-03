# SERVICE-003-when-to-use

## Pattern

Decision guide for choosing between Actions, Services, or neither.

## Dependencies

- `services/SERVICE-001-actions.md` - Business operations
- `services/SERVICE-002-domain-services.md` - Domain utilities

## Decision Tree

```
Need to implement business logic?

├─ Complex business operation (create, update, process)?
│  ├─ Multi-step process?
│  │  └─ Use Action (CreateHouseholdAction)
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
class CreateHouseholdAction
{
    public function execute(HouseholdData $data): Household
    {
        $household = Household::create([...]);
        $this->assignOwner($household, $data->userId);
        event(new HouseholdCreated($household));
        return $household;
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
$action->execute($request->toData());

// Job
$action->execute(PaymentData::fromInput($this->payload));

// Command
$action->execute(new PaymentData(...));
```

### Use Service

**Focused domain utility:**
```php
// ✅ Use Service - specific purpose (budget calculations)
class BudgetCalculator
{
    public function calculateAllocation(int $income): array
    public function projectSavings(int $amount, int $months): int
    public function calculateVariance(Collection $transactions, array $limits): array
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
class CreateBudgetAction
{
    public function __construct(
        private BudgetCalculator $calculator,  // Service
    ) {
    }

    public function execute(BudgetData $data): Budget
    {
        $allocation = $this->calculator->calculateAllocation($data->monthlyIncome);

        return Budget::create([
            'user_id' => $data->userId,
            'monthly_income' => $data->monthlyIncome,
            'needs_allocation' => $allocation['needs'],
            'wants_allocation' => $allocation['wants'],
            'savings_allocation' => $allocation['savings'],
        ]);
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
// Bad - BudgetCalculator persisting data?
class BudgetCalculator
{
    public function calculateAllocation(int $income): array
    public function saveBudgetToDatabase(array $data): Budget  // Wrong!
}

// Better - separate concerns
class BudgetCalculator  // Only calculations
class CreateBudgetAction  // Handles persistence
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
