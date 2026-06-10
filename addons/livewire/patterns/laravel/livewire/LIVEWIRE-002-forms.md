# LIVEWIRE-002-forms

## Pattern

A **Form object** extracts a component's form state, validation rules, and persistence logic into a dedicated class (`extends Livewire\Form`). It keeps the component lean, makes the form reusable across create/edit components, and groups related fields under one `$form` property. Reach for a Form object once a form has more than a field or two.

This builds on the class-based component conventions.

## Structure

**Scaffold:**
```bash
php artisan livewire:form OrderForm
```

Generates `app/Livewire/Forms/OrderForm.php` (match the project's actual Livewire namespace).

**Form object:**
```php
<?php

declare(strict_types=1);

namespace App\Livewire\Forms;

use Livewire\Attributes\Validate;
use Livewire\Form;

class OrderForm extends Form
{
    #[Validate('required|string|min:3')]
    public string $reference = '';

    #[Validate('required|numeric|min:0')]
    public $total = 0;

    #[Validate('nullable|string|max:1000')]
    public string $notes = '';
}
```

Use a `rules()` method on the form instead of attributes when rules are dynamic (e.g. a `unique` rule that must ignore the current record on edit).

## Using a Form object in a component

```php
<?php

declare(strict_types=1);

namespace App\Livewire;

use App\Livewire\Forms\OrderForm;
use App\Models\Order;
use Livewire\Component;

class CreateOrder extends Component
{
    public OrderForm $form;

    public function save(): void
    {
        $this->validate();   // validates the whole $form

        Order::create($this->form->only(['reference', 'total', 'notes']));

        $this->redirect('/orders');
    }

    public function render()
    {
        return view('livewire.create-order');
    }
}
```

```blade
<form wire:submit="save">
    <input type="text" wire:model="form.reference">
    @error('form.reference') <span class="error">{{ $message }}</span> @enderror

    <input type="number" wire:model="form.total">
    @error('form.total') <span class="error">{{ $message }}</span> @enderror

    <button type="submit">Save</button>
</form>
```

Bind inputs with the **dotted** `wire:model="form.reference"` and surface errors with `@error('form.reference')`.

## Edit: filling and updating

Populate a form from an existing model with `fill()`, and write back with the form's own helpers:

```php
public Order $order;
public OrderForm $form;

public function mount(Order $order): void
{
    $this->order = $order;
    $this->form->fill($order->only(['reference', 'total', 'notes']));
}

public function update(): void
{
    $this->validate();

    $this->order->update($this->form->only(['reference', 'total', 'notes']));

    $this->redirect('/orders/'.$this->order->id);
}
```

Use `$this->form->only([...])` / `$this->form->except([...])` to control exactly which keys reach the model — don't pass the whole form blindly.

## File uploads

Use the `WithFileUploads` trait on the **component** (not the form object). Validate the upload like any property; the bound property holds a `TemporaryUploadedFile` until you store it.

```php
<?php

declare(strict_types=1);

namespace App\Livewire;

use Livewire\Attributes\Validate;
use Livewire\Component;
use Livewire\WithFileUploads;

class UploadInvoice extends Component
{
    use WithFileUploads;

    #[Validate('required|file|mimes:pdf|max:2048')]   // max in KB
    public $invoice;

    public function save(): void
    {
        $this->validate();

        $path = $this->invoice->store('invoices');   // returns a stored path

        // persist $path on the model...
    }

    public function render()
    {
        return view('livewire.upload-invoice');
    }
}
```

```blade
<form wire:submit="save">
    <input type="file" wire:model="invoice">
    @error('invoice') <span class="error">{{ $message }}</span> @enderror

    <div wire:loading wire:target="invoice">Uploading…</div>

    <button type="submit">Save</button>
</form>
```

For multiple files, type the property as an array (`public array $invoices = [];`), bind `wire:model="invoices"` on a `multiple` input, and validate with a nested rule (`'invoices.*' => 'file|mimes:pdf'`).

## Key Points

- Form object `extends Livewire\Form`; scaffold with `php artisan livewire:form`.
- Fields are public properties with `#[Validate]` (or a `rules()` method for dynamic rules).
- Hold it as a typed public property (`public OrderForm $form`) on the component.
- Bind dotted: `wire:model="form.field"`; errors via `@error('form.field')`.
- `$this->validate()` on the component validates the whole form.
- `fill()` to load from a model on edit; `only()`/`except()` to control what's written back.
- File uploads: `WithFileUploads` trait on the component; store with `->store('dir')`; size limits are in **KB**.

## Compliance

- ⚠️ **Validate uploads strictly** — pin `mimes:`/`mimetypes:` and a `max:` size. An unbounded `file` rule lets a user push arbitrary, large files to temp storage.
- ⚠️ **Control mass assignment** — use `only([...])`/`except([...])` so a user can't smuggle an extra `wire:model="form.role"` field into the create/update payload. Don't pass the raw form to a model.
- ⚠️ Re-authorize on **edit/update** — confirm the current user owns the record in `mount()`/the action, not just at the route.
