# LIVEWIRE-003-volt

## Pattern

**Volt** is an officially-supported way to write Livewire components as a **single file** — the PHP logic and the Blade template live together in one `.blade.php` file. It offers two styles:

- **Functional API** — declare state and actions with helper functions (`state()`, `computed()`, `mount()`, etc.). Terse, great for small/medium components.
- **Class API** — an anonymous class in the same file. Identical semantics to a normal class-based component, just colocated with the view.

Volt is a separate package (`livewire/volt`). Use it for self-contained components where one file is clearer than two; reach back for full class-based components when logic is substantial or shared.

## Structure

**Scaffold:**
```bash
php artisan make:volt show-order            # functional (default)
php artisan make:volt show-order --class    # class-based single-file
```

Generates a single file under `resources/views/livewire/` (e.g. `resources/views/livewire/show-order.blade.php`).

## Functional component

```blade
<?php

use App\Models\Order;
use function Livewire\Volt\{state, computed, mount};

state(['orderId' => null]);

mount(function (int $orderId) {
    $this->orderId = $orderId;
});

$order = computed(fn () => Order::find($this->orderId));

$markPaid = function () {
    $this->order->markPaid();
};

?>

<div>
    <h1>{{ $this->order->reference }}</h1>

    <button wire:click="markPaid">Mark paid</button>
</div>
```

- `state([...])` declares public properties (the wire-serialized state).
- `computed(fn () => ...)` is the functional equivalent of `#[Computed]` — accessed as `$this->name`.
- A closure assigned to a `$variable` becomes an **action** callable from the view by that name (`wire:click="markPaid"`).
- `mount(fn (...) => ...)` runs once with route/parent params.

## Validation in a functional component

```blade
<?php

use App\Models\Order;
use function Livewire\Volt\{state, rules};

state(['reference' => '', 'total' => 0]);

rules([
    'reference' => 'required|string|min:3',
    'total' => 'required|numeric|min:0',
]);

$save = function () {
    $this->validate();

    Order::create([
        'reference' => $this->reference,
        'total' => $this->total,
    ]);

    $this->redirect('/orders');
};

?>

<form wire:submit="save">
    <input type="text" wire:model="reference">
    @error('reference') <span class="error">{{ $message }}</span> @enderror

    <button type="submit">Save</button>
</form>
```

You can also reuse a **Form object** inside Volt:

```blade
<?php

use App\Livewire\Forms\OrderForm;
use function Livewire\Volt\form;

form(OrderForm::class);

$save = function () {
    $this->validate();

    \App\Models\Order::create($this->form->only(['reference', 'total']));
};

?>

<form wire:submit="save">
    <input type="text" wire:model="form.reference">
    @error('form.reference') <span class="error">{{ $message }}</span> @enderror

    <button type="submit">Save</button>
</form>
```

## Class-based single-file component

When you prefer class syntax but still want one file:

```blade
<?php

use App\Models\Order;
use Livewire\Attributes\Computed;
use Livewire\Volt\Component;

new class extends Component {
    public int $orderId;

    public function mount(int $orderId): void
    {
        $this->orderId = $orderId;
    }

    #[Computed]
    public function order()
    {
        return Order::find($this->orderId);
    }

    public function markPaid(): void
    {
        $this->order->markPaid();
    }
}; ?>

<div>
    <h1>{{ $this->order->reference }}</h1>
    <button wire:click="markPaid">Mark paid</button>
</div>
```

This is exactly the class-based component model (`#[Validate]`, `#[On]`, lifecycle hooks, events all apply) — just authored inline as an anonymous class.

## Key Points

- Volt = single-file Livewire; package `livewire/volt`, scaffold `php artisan make:volt`.
- **Functional**: `state()`, `computed()`, `rules()`, `mount()`; a `$var = fn` closure is an action.
- **Class-based single-file**: `new class extends Volt\Component { ... }` — same semantics as a class-based component.
- Computed values accessed as `$this->name` in the view.
- Form objects work in Volt via the `form()` helper.
- Choose Volt for self-contained components; choose two-file class components for larger or shared logic.

## Compliance

- ⚠️ The same exposure rules apply: `state()` properties are client-writable. Don't keep prices, roles, or owner ids in mutable state — derive them with `computed()` or lock them.
- ⚠️ Always `$this->validate()` / re-authorize inside actions before persisting — colocating with the view doesn't change the trust boundary.
