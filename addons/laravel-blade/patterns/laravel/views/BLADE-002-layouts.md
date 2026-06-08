# Blade layouts

A layout as a **component** (the modern approach) — not `@extends`. The page nests inside `<x-layout>`.

```blade
{{-- resources/views/components/layout.blade.php --}}
@props(['title' => config('app.name')])

<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @stack('head')
</head>
<body>
    <x-nav />
    <main class="container">
        {{ $slot }}
    </main>
    @stack('scripts')
</body>
</html>
```

```blade
{{-- a page --}}
<x-layout title="Orders">
    <h1>Orders</h1>
    {{-- ... --}}
    @push('scripts')
        <script src="..."></script>
    @endpush
</x-layout>
```

## Conventions

- **Layout = component** (`<x-layout>`), pages nest in it — composable, testable, no `@yield`/`@section` indirection.
- **`@stack` / `@push`** for page-specific head/scripts.
- **`@vite([...])`** for assets. One root layout; specialized layouts (`<x-layout.auth>`) compose it.
- Navigation, flash messages, and chrome live in the layout (or components it includes), not repeated per page.

## Don't

- Don't mix the component-layout approach with legacy `@extends`/`@section` in the same project — pick one (prefer components).
- Don't hard-code asset paths — use `@vite`.

## See also

- [BLADE-001-components](BLADE-001-components.md) · [BLADE-004-pages](BLADE-004-pages.md)
