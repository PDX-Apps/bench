# Blade forms

Server-rendered forms with CSRF, method spoofing, validation errors, and old input.

```blade
<form method="POST" action="{{ route('orders.store') }}">
    @csrf

    <div>
        <label for="reference">Reference</label>
        <input id="reference" name="reference" value="{{ old('reference') }}"
               @error('reference') aria-invalid="true" @enderror>
        @error('reference')
            <p class="error">{{ $message }}</p>
        @enderror
    </div>

    <div>
        <label for="status">Status</label>
        <select id="status" name="status">
            @foreach (OrderStatus::cases() as $status)
                <option value="{{ $status->value }}" @selected(old('status') === $status->value)>
                    {{ $status->label() }}
                </option>
            @endforeach
        </select>
    </div>

    <button type="submit">Create order</button>
</form>
```

Edit form — spoof the method:

```blade
<form method="POST" action="{{ route('orders.update', $order) }}">
    @csrf
    @method('PUT')
    <input name="reference" value="{{ old('reference', $order->reference) }}">
    {{-- ... --}}
</form>
```

## Conventions

- **`@csrf`** on every mutating form; **`@method('PUT'|'PATCH'|'DELETE')`** for non-POST.
- **`old('field', $fallback)`** repopulates after a validation redirect (controller validates via a FormRequest, redirects back with errors).
- **`@error('field')`** shows the message; mark the input invalid (`aria-invalid`) for accessibility.
- **`@selected` / `@checked` / `@disabled`** directives instead of manual ternaries.
- **Always `<label for>`** tied to an input `id`. Submit posts to a named route.

## Don't

- Don't skip `@csrf`. Don't echo `old()` without it being escaped (it is, via `{{ }}`).
- Don't put validation logic in the view — that's the FormRequest's job; the view only displays `@error` messages.
