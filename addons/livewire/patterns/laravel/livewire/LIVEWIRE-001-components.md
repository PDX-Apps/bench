# LIVEWIRE-001-components

## Pattern

A Livewire component is a PHP class plus a Blade view that together render a piece of reactive UI. The class holds **state** (public properties), exposes **actions** (public methods the browser can call), and the view binds to both. Livewire diffs the rendered HTML on each round-trip and patches the DOM — no hand-written JavaScript, no SPA.

Use a Livewire component when you want server-rendered interactivity (live search, inline edit, a wizard, a cart) without standing up a separate Vue/React frontend.

> **Version:** this pattern targets **Livewire 3** (still the widely-deployed stable). **Livewire 4** is released and changes a few things — single-file components by default, and `wire:model` now only listens to events on the element itself (add `.deep` to capture child-element events, the old behavior). On a v4 project, check the docs for the new template/component conventions; the core attribute/property/action model below is unchanged.

## Structure

**Scaffold:**
```bash
php artisan make:livewire ShowOrder
# or namespaced:
php artisan make:livewire Orders/ShowOrder
```

This generates two files — the class (under the app's Livewire namespace, e.g. `app/Livewire/ShowOrder.php`) and the view (`resources/views/livewire/show-order.blade.php`). Match wherever the project already keeps its Livewire classes.

**Basic component:**
```php
<?php

declare(strict_types=1);

namespace App\Livewire;

use App\Models\Order;
use Livewire\Component;

class ShowOrder extends Component
{
    public Order $order;

    public function render()
    {
        return view('livewire.show-order');
    }
}
```

```blade
{{-- resources/views/livewire/show-order.blade.php --}}
<div>
    <h1>{{ $order->reference }}</h1>
    <p>Total: {{ $order->total }}</p>
</div>
```

A component's view must have **exactly one root element**.

## Properties (state)

Public properties are the component's state. They are sent to the browser, can be bound with `wire:model`, and persist across requests.

```php
public string $search = '';
public int $perPage = 10;
public bool $showArchived = false;
```

- Properties must hold values Livewire can serialize: primitives, arrays, and supported types (Eloquent models, collections, `Carbon`, enums). Don't store closures or arbitrary objects.
- Bind a property to an input with `wire:model="search"` (deferred) or `wire:model.live="search"` (sync on every keystroke). In Livewire 3 `wire:model` is **deferred by default** — use `.live` for real-time updates.
- Lock a property the browser must not change with `#[Locked]`:

```php
use Livewire\Attributes\Locked;

#[Locked]
public int $orderId;
```

## Computed properties

Derive read-only values with `#[Computed]`. They're memoized per request and accessed as `$this->property` in PHP and `$this->property` in the view — without the parentheses of a method call.

```php
use Livewire\Attributes\Computed;

#[Computed]
public function order()
{
    return Order::find($this->orderId);
}

public function markPaid(): void
{
    $this->order->markPaid();   // accessed as a property
}
```

Prefer a computed property over a public property for data you can recompute (e.g. a looked-up model) — it keeps that data off the wire and out of the serialized payload.

## Actions

Public methods are actions — call them from the view with `wire:click`, `wire:submit`, etc.

```php
public function archive(): void
{
    $this->order->archive();

    $this->dispatch('order-archived', id: $this->order->id);
}
```

```blade
<button wire:click="archive">Archive</button>
```

Actions can accept arguments from the view (`wire:click="archive({{ $id }})"`), but treat them as untrusted input — validate/authorize inside the method.

## Validation

Co-locate rules on the property with `#[Validate]`. Livewire validates a property as it updates; call `$this->validate()` before persisting to validate everything at once.

```php
use Livewire\Attributes\Validate;

class CreateOrder extends Component
{
    #[Validate('required|string|min:3')]
    public string $reference = '';

    #[Validate('required|numeric|min:0')]
    public $total = 0;

    public function save(): void
    {
        $this->validate();

        Order::create([
            'reference' => $this->reference,
            'total' => $this->total,
        ]);

        $this->redirect('/orders');
    }
}
```

For dynamic or complex rules, define a `rules()` method instead of attributes:

```php
protected function rules(): array
{
    return [
        'reference' => ['required', 'string', 'unique:orders,reference'],
        'total' => ['required', 'numeric', 'min:0'],
    ];
}
```

When a form grows past a couple of fields, extract it into a **Form object**.

## Lifecycle hooks

```php
public function mount(int $orderId): void
{
    // Runs once, when the component is first created. Receives route/parent params.
    $this->orderId = $orderId;
}

public function updatedReference(string $value): void
{
    // Runs after the `reference` property is updated from the browser.
}

public function updated(string $name, mixed $value): void
{
    // Runs after ANY property update. $name is the property name.
}
```

`mount()` is the constructor equivalent — initialize state there. The `updated{Property}()` hooks are where you react to a specific field changing (e.g. recompute a dependent value).

## Events

Components communicate by dispatching events and listening with `#[On]`.

```php
use Livewire\Attributes\On;

// Dispatch from any action:
$this->dispatch('order-archived', id: $this->order->id);

// Listen in another component:
#[On('order-archived')]
public function refreshList(int $id): void
{
    unset($this->orders);   // bust a #[Computed] cache, then re-render
}
```

Dispatch to a specific component with `->to(OtherComponent::class)`, or restrict it to **only the component that fired it** with `->self()`. (To handle an event purely in the browser, listen with Alpine/`$wire.on(...)` rather than dispatching server-side.)

## Key Points

- A component = a PHP class (`extends Livewire\Component`) + a single-root Blade view.
- Public properties are serialized state; `wire:model` is **deferred by default** in Livewire 3 (use `.live` for real-time).
- `#[Computed]` for derived/looked-up data — keeps it off the wire, accessed as `$this->name`.
- Public methods are actions; treat their arguments as untrusted.
- `#[Validate]` co-locates rules; `rules()` for dynamic rules; `$this->validate()` before persisting.
- Lifecycle: `mount()` once, `updated{Property}()` / `updated()` on changes.
- `$this->dispatch()` + `#[On]` for cross-component communication.
- `#[Locked]` on any property the browser must not be able to mutate.

## Compliance

- ⚠️ **Public properties are exposed to and writable from the browser.** Never put a price, role, owner id, or any authorization-relevant value in an unlocked public property. Use `#[Locked]`, or derive it server-side with `#[Computed]`.
- ⚠️ **Action arguments come from the client.** Re-authorize (`$this->authorize(...)`) and validate inside the action — don't trust an id passed from the view.
- ⚠️ Mass-assignment still applies: validate before `create()`/`update()`; don't pass raw `$this->all()` into a model.
