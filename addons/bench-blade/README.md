# bench-blade

The **Laravel Blade UI track** — for server-rendered apps that use Blade instead of a Vue/React SPA.

## What it ships
- **Patterns** — `BLADE-001` components (anonymous + class-based), `BLADE-002` layouts (component-based, slots/stacks), `BLADE-003` forms (CSRF, validation errors, old input), `BLADE-004` pages (controller → view, collections, pagination).
- **`/blade`** skill → **`blade-component`** + **`blade-page`** agents.

## When to use
Your Laravel app renders HTML with Blade (optionally + Livewire/Alpine), not a JS SPA. If you use a SPA frontend, use bench's core `vue`/`react` track instead. Pair with **bench-livewire** for reactive components.

## Install
```bash
bench addon add /path/to/bench/addons/bench-blade && bench rebuild
```
