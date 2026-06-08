# livewire

Build **server-rendered, reactive UI** for Laravel with **Livewire 3** (optionally **Volt**) — a Blade-based alternative to a Vue/React SPA. Write interactive components (live search, inline edit, wizards, forms) entirely in PHP, no SPA to stand up.

## What it ships

- **`/livewire`** skill + **`livewire-component`** agent — scaffold (`php artisan make:livewire` / `make:volt` / `livewire:form`) and implement one component, its view, and any Form object.
- **Patterns:**
  - `LIVEWIRE-001-components` — class-based component conventions: public properties, `#[Computed]`, actions, `wire:model`, `#[Validate]`/`rules()`, lifecycle hooks, events, `#[Locked]`.
  - `LIVEWIRE-002-forms` — Form objects (`extends Livewire\Form`), dotted binding, edit/fill, and file uploads (`WithFileUploads`).
  - `LIVEWIRE-003-volt` — Volt single-file components (functional + class styles).

## Install

```bash
bench addon add /path/to/bench/addons/livewire
bench rebuild
```

Then:

```
/livewire CreateOrder with a reference + total form, validated, saving an Order
/livewire ShowOrder Volt component with a markPaid action
```

## Requires

- Livewire 3 (`composer require livewire/livewire`).
- For Volt components: `composer require livewire/volt` + `php artisan volt:install`.
