# Blade components

Reusable UI via Blade components. Prefer **anonymous** components (a single `.blade.php`) for presentational pieces; use **class-based** components when there's real logic.

## Anonymous component

```blade
{{-- resources/views/components/card.blade.php --}}
@props(['title' => null, 'footer' => null])

<div {{ $attributes->merge(['class' => 'card']) }}>
    @isset($title)
        <div class="card__header">{{ $title }}</div>
    @endisset

    <div class="card__body">{{ $slot }}</div>

    @isset($footer)
        <div class="card__footer">{{ $footer }}</div>
    @endisset
</div>
```

```blade
<x-card title="Order #{{ $order->reference }}" class="mb-4">
    {{ $order->summary }}
    <x-slot:footer>Placed {{ $order->created_at->diffForHumans() }}</x-slot:footer>
</x-card>
```

## Class-based component (when there's logic)

```php
// app/View/Components/StatusBadge.php
final class StatusBadge extends Component
{
    public function __construct(public OrderStatus $status) {}

    public function color(): string
    {
        return match ($this->status) {
            OrderStatus::Paid => 'green',
            OrderStatus::Pending => 'amber',
            OrderStatus::Cancelled => 'red',
        };
    }

    public function render(): View
    {
        return view('components.status-badge');
    }
}
```

## Conventions

- **`@props([...])`** declares inputs (with defaults) — everything else falls through `$attributes`.
- **`$attributes->merge([...])`** / `->class([...])` so callers can add classes/attrs without breaking the component.
- **Named slots** via `<x-slot:name>`; default content via `{{ $slot }}`.
- **One responsibility per component**; compose small ones. Presentational → anonymous; behavioural/derived → class-based.
- **Escape by default** (`{{ }}`); only `{!! !!}` for trusted HTML you control.
- Keep PHP in components/view-models, not sprawled in the template; pass ready-to-render data from the controller.

## Don't

- Don't query the database in a component — pass data in from the controller/view composer.
- Don't `{!! !!}` user input. Don't duplicate a partial that should be a component.

## See also

- [BLADE-002-layouts](BLADE-002-layouts.md) · [BLADE-003-forms](BLADE-003-forms.md) · [BLADE-004-pages](BLADE-004-pages.md)
