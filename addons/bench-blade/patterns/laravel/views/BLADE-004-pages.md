# Blade pages (views)

A page view: a controller returns `view()` with ready-to-render data; the view composes components inside the layout.

```php
// controller
public function index(): View
{
    return view('orders.index', [
        'orders' => Order::query()->latest()->paginate(20),
    ]);
}
```

```blade
{{-- resources/views/orders/index.blade.php --}}
<x-layout title="Orders">
    <div class="page-header">
        <h1>Orders</h1>
        <a href="{{ route('orders.create') }}">New order</a>
    </div>

    @forelse ($orders as $order)
        <x-order-row :order="$order" />
    @empty
        <x-empty-state message="No orders yet." />
    @endforelse

    {{ $orders->links() }}
</x-layout>
```

## Conventions

- **Controller passes ready data** (paginated, eager-loaded) — the view doesn't query.
- **`@forelse`/`@empty`** for collections with an empty state; **`{{ $paginator->links() }}`** for pagination.
- **Compose components** (`<x-order-row>`) rather than inlining markup; pass models with `:order="$order"`.
- **Folder = resource** (`orders/index`, `orders/show`, `orders/create`, `orders/edit`).
- Flash messages (`session('status')`) surface in the layout, not each page.

## Don't

- Don't run queries or business logic in the view. Don't N+1 — eager-load in the controller.
- Don't repeat layout chrome per page — it lives in `<x-layout>`.

## See also

- [BLADE-001-components](BLADE-001-components.md) · [BLADE-002-layouts](BLADE-002-layouts.md) · [BLADE-003-forms](BLADE-003-forms.md)
